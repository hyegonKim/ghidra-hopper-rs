//! Bitmask MOVI D/V.2D and 128-bit SIMD pair transfers. Vector indices are
//! deliberately separate from GPR Varnodes, including V31 versus SP/ZR.
use crate::pcode_sleigh::{DecodedInstruction, PcodeOp, SpaceKind, Varnode};
pub fn expanded_bytes(immediate: u8) -> u64 {
    (0..8).fold(0, |out, n| {
        out | if immediate & (1 << n) != 0 {
            255u64 << (8 * n)
        } else {
            0
        }
    })
}
fn temp(offset: u64) -> Varnode {
    Varnode {
        space: SpaceKind::Unique,
        offset,
        size: 8,
    }
}
pub fn decode(address: u64, word: u32) -> Option<DecodedInstruction> {
    let mut i = DecodedInstruction {
        address,
        bytes: word.to_le_bytes(),
        mnemonic: String::new(),
        raw_args: vec![],
        formatted_args: vec![],
        is_conditional_jump: false,
        is_unconditional_jump: false,
        is_call: false,
        is_ret: false,
        branch_target: None,
        call_ref: None,
        pcode: vec![],
    };
    if word & 0xbff8fc00 == 0x2f00e400 {
        let register = (word & 31) as u8;
        let full = word & (1 << 30) != 0;
        let imm = ((((word >> 16) & 7) << 5) | ((word >> 5) & 31)) as u8;
        let low = expanded_bytes(imm);
        let high = if full { low } else { 0 };
        i.mnemonic = "movi".into();
        i.raw_args = vec![
            if full {
                format!("v{register}.2d")
            } else {
                format!("d{register}")
            },
            format!("#0x{low:016x}"),
        ];
        i.pcode = vec![PcodeOp::VectorImmediate {
            register,
            low,
            high,
        }];
    } else if word & 0x3e000000 == 0x2c000000 && word >> 30 == 2 {
        let mode = (word >> 23) & 3;
        let load = word & (1 << 22) != 0;
        let first = (word & 31) as u8;
        let second = ((word >> 10) & 31) as u8;
        if mode == 0 || (load && first == second) {
            return None;
        }
        let rn = ((word >> 5) & 31) as u64;
        let base = Varnode::reg(rn, 8);
        let displacement =
            ((((word >> 15) & 127) as i64) - if word & (1 << 21) != 0 { 128 } else { 0 }) * 16;
        i.mnemonic = if load { "ldp" } else { "stp" }.into();
        let memory = match mode {
            1 => format!("[{}], #{displacement}", base.display_arm64()),
            3 => format!("[{}, #{displacement}]!", base.display_arm64()),
            _ => format!("[{}, #{displacement}]", base.display_arm64()),
        };
        i.raw_args = vec![format!("q{first}"), format!("q{second}"), memory];
        i.pcode = vec![
            PcodeOp::IntAdd {
                dst: temp(0),
                lhs: base,
                rhs: Varnode::imm(if mode == 1 { 0 } else { displacement as u64 }, 8),
            },
            PcodeOp::IntAdd {
                dst: temp(1),
                lhs: temp(0),
                rhs: Varnode::imm(16, 8),
            },
        ];
        for (register, addr) in [(first, temp(0)), (second, temp(1))] {
            i.pcode.push(if load {
                PcodeOp::VectorLoad { register, addr }
            } else {
                PcodeOp::VectorStore { register, addr }
            });
        }
        if mode != 2 {
            i.pcode.push(PcodeOp::IntAdd {
                dst: base,
                lhs: base,
                rhs: Varnode::imm(displacement as u64, 8),
            });
        }
    } else {
        return None;
    }
    i.formatted_args = i.raw_args.clone();
    Some(i)
}
