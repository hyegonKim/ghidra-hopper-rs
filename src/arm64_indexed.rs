//! Unsigned halfword load with an extended register offset; no base writeback.
use crate::pcode_sleigh::{DecodedInstruction, PcodeOp, SpaceKind, Varnode};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IndexExtend {
    Uxtw,
    Uxtx,
    Sxtw,
    Sxtx,
}

pub fn address(base: u64, index: u64, extend: IndexExtend, shift: u8) -> Option<u64> {
    if shift > 1 {
        return None;
    }
    let offset = match extend {
        IndexExtend::Uxtw => index as u32 as u64,
        IndexExtend::Uxtx => index,
        IndexExtend::Sxtw => index as u32 as i32 as i64 as u64,
        IndexExtend::Sxtx => index as i64 as u64,
    };
    Some(base.wrapping_add(offset.wrapping_shl(shift as u32)))
}

fn temp(offset: u64, size: u8) -> Varnode {
    Varnode {
        space: SpaceKind::Unique,
        offset,
        size,
    }
}
pub fn decode(pc: u64, word: u32) -> Option<DecodedInstruction> {
    if word & 0xffe00c00 != 0x78600800 {
        return None;
    }
    let option = (word >> 13) & 7;
    let (extend, index_size, extend_name) = match option {
        2 => (IndexExtend::Uxtw, 4, "uxtw"),
        3 => (IndexExtend::Uxtx, 8, "lsl"),
        6 => (IndexExtend::Sxtw, 4, "sxtw"),
        7 => (IndexExtend::Sxtx, 8, "sxtx"),
        _ => return None,
    };
    let shift = ((word >> 12) & 1) as u8;
    let rn = ((word >> 5) & 31) as u64;
    let rm = ((word >> 16) & 31) as u64;
    let rt = (word & 31) as u64;
    let base = Varnode::reg(rn, 8);
    let index = if rm == 31 {
        Varnode::imm(0, index_size)
    } else {
        Varnode::reg(rm, index_size)
    };
    let dst = if rt == 31 {
        temp(2, 4)
    } else {
        Varnode::reg(rt, 4)
    };
    let index_name = if rm == 31 {
        if index_size == 4 { "wzr" } else { "xzr" }.into()
    } else {
        index.display_arm64()
    };
    let destination = if rt == 31 {
        "wzr".into()
    } else {
        dst.display_arm64()
    };
    let extension = if option == 3 && shift == 0 {
        String::new()
    } else {
        format!(", {extend_name} #{shift}")
    };
    let args = vec![
        destination,
        format!("[{}, {}{}]", base.display_arm64(), index_name, extension),
    ];
    Some(DecodedInstruction {
        address: pc,
        bytes: word.to_le_bytes(),
        mnemonic: "ldrh".into(),
        raw_args: args.clone(),
        formatted_args: args,
        is_conditional_jump: false,
        is_unconditional_jump: false,
        is_call: false,
        is_ret: false,
        branch_target: None,
        call_ref: None,
        pcode: vec![
            PcodeOp::RegisterOffset {
                dst: temp(0, 8),
                base,
                index,
                extend,
                shift,
            },
            PcodeOp::Load {
                dst: temp(1, 2),
                addr: temp(0, 8),
            },
            PcodeOp::ZeroExtend {
                dst,
                src: temp(1, 2),
            },
        ],
    })
}
