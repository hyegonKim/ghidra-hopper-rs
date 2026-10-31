use ghidra_hopper_rs::{
    ghidra_port::GhidraProgram, ghidra_port::HopperHybridObjcAnalyzerRs, macho_objc::MachOImage,
    pcode_sleigh::PcodeOp,
};
fn p32(b: &mut [u8], o: usize, v: u32) {
    b[o..o + 4].copy_from_slice(&v.to_le_bytes());
}
fn p64(b: &mut [u8], o: usize, v: u64) {
    b[o..o + 8].copy_from_slice(&v.to_le_bytes());
}
fn section(b: &mut [u8], at: usize, name: &[u8], layout: (u64, u32, u64), flags: u32, first: u32) {
    let (addr, off, size) = layout;
    b[at..at + name.len()].copy_from_slice(name);
    p64(b, at + 32, addr);
    p64(b, at + 40, size);
    p32(b, at + 48, off);
    p32(b, at + 64, flags);
    p32(b, at + 68, first);
}
fn fixture() -> Vec<u8> {
    let mut b = vec![0; 0x1000];
    p32(&mut b, 0, 0xfeedfacf);
    p32(&mut b, 4, 0x100000c);
    p32(&mut b, 12, 6);
    p32(&mut b, 16, 5);
    p32(&mut b, 20, 544);
    p32(&mut b, 24, 0x84);
    for (at, vm, off, len, prot, count, cmdsize) in [
        (32, 0x1000, 0, 0x500, 5, 2, 232),
        (264, 0x2000, 0x600, 0x100, 3, 1, 152),
    ] {
        p32(&mut b, at, 0x19);
        p32(&mut b, at + 4, cmdsize);
        p64(&mut b, at + 24, vm);
        p64(&mut b, at + 32, 0x1000);
        p64(&mut b, at + 40, off);
        p64(&mut b, at + 48, len);
        p32(&mut b, at + 56, prot);
        p32(&mut b, at + 60, prot);
        p32(&mut b, at + 64, count);
    }
    b[40..46].copy_from_slice(b"__TEXT");
    b[272..278].copy_from_slice(b"__DATA");
    section(
        &mut b,
        104,
        b"__objc_stubs",
        (0x1300, 0x300, 32),
        0x80000400,
        0,
    );
    section(&mut b, 184, b"__objc_selrefs", (0x1400, 0x400, 8), 0, 0);
    section(&mut b, 336, b"__got", (0x2000, 0x600, 8), 6, 1);
    p32(&mut b, 416, 2);
    p32(&mut b, 420, 24);
    p32(&mut b, 424, 0x800);
    p32(&mut b, 428, 1);
    p32(&mut b, 432, 0x840);
    p32(&mut b, 436, 32);
    p32(&mut b, 440, 11);
    p32(&mut b, 444, 80);
    p32(&mut b, 496, 0x880);
    p32(&mut b, 500, 2);
    p32(&mut b, 520, 0xc);
    p32(&mut b, 524, 56);
    p32(&mut b, 528, 24);
    let lib = b"/usr/lib/libobjc.A.dylib\0";
    b[544..544 + lib.len()].copy_from_slice(lib);
    for (n, w) in [0x90000001, 0xf9420021, 0xb0000010, 0xf9400210, 0xd61f0200]
        .iter()
        .enumerate()
    {
        p32(&mut b, 0x300 + n * 4, *w);
    }
    p64(&mut b, 0x400, 0x801000000000dead);
    p64(&mut b, 0x600, 0x801000000000beef);
    p32(&mut b, 0x800, 1);
    b[0x804] = 1;
    b[0x807] = 1;
    let name = b"\0_objc_msgSend\0";
    b[0x840..0x840 + name.len()].copy_from_slice(name);
    b
}
#[test]
fn objc_tail_resolves_import_but_never_invents_selector_or_runtime_pointer() {
    let image = MachOImage::parse(&fixture()).unwrap();
    let binding = &image.objc.macho_imports[&0x1310];
    assert_eq!(binding.symbol, "_objc_msgSend");
    assert_eq!(binding.selector_address, Some(0x1400));
    assert_eq!(binding.instructions.len(), 5);
    let mut p = GhidraProgram::from_macho_image("objc", &image);
    let mut analyzer = HopperHybridObjcAnalyzerRs::new();
    let f = analyzer.analyze_function_zero_ipc(&mut p, "objc", 0x1300, 16, &[]);
    assert!(!f.is_incomplete());
    assert!(analyzer.discovered_messages.is_empty());
    let text = f.render_four_modes(&p.segments[0]);
    assert!(text.contains("name and runtime value unresolved"));
    assert!(!text.contains("0000dead") && !text.contains("0000beef"));
    assert!(matches!(
        f.basic_blocks[0].instructions[4].pcode[0],
        PcodeOp::MachOImportTailCall {
            selector_address: Some(0x1400),
            ..
        }
    ));
}
#[test]
fn objc_suffix_adrp_uses_its_own_page_across_boundary() {
    let mut b = fixture();
    p64(&mut b, 32 + 24, 0x1cf8);
    p64(&mut b, 104 + 32, 0x1ff8);
    p64(&mut b, 184 + 32, 0x20f8);
    p64(&mut b, 264 + 24, 0x3000);
    p64(&mut b, 336 + 32, 0x3000);
    p32(&mut b, 0x300, 0xb0000001);
    p32(&mut b, 0x304, 0xf9407c21);
    let image = MachOImage::parse(&b).unwrap();
    let binding = &image.objc.macho_imports[&0x2008];
    assert_eq!(binding.pointer_address, 0x3000);
    assert_eq!(binding.selector_address, Some(0x20f8));
}
#[test]
fn malformed_prefix_selector_mapping_or_import_identity_stays_unresolved() {
    for (at, word) in [
        (0x300, 0x90000000),
        (0x304, 0xf9420421),
        (0x308, 0xb0000011),
        (184 + 48, 0x408),
        (336 + 68, 100),
    ] {
        let mut b = fixture();
        p32(&mut b, at, word);
        let image = MachOImage::parse(&b).unwrap();
        assert!(image.objc.macho_imports.is_empty(), "{at:x}");
    }
    let mut b = fixture();
    b[544..576].fill(0);
    b[544..552].copy_from_slice(b"private\0");
    assert!(MachOImage::parse(&b).unwrap().objc.macho_imports.is_empty());
    let mut b = fixture();
    b[0x841] = b'X';
    assert!(MachOImage::parse(&b).unwrap().objc.macho_imports.is_empty());
}
#[test]
fn incomplete_or_changed_objc_stub_cannot_reuse_full_prefix_proof() {
    for (entry, budget) in [(0x1308, 16), (0x1300, 4)] {
        let image = MachOImage::parse(&fixture()).unwrap();
        let mut p = GhidraProgram::from_macho_image("partial", &image);
        let f = HopperHybridObjcAnalyzerRs::new().analyze_function_zero_ipc(
            &mut p,
            "partial",
            entry,
            budget,
            &[],
        );
        assert!(f.is_incomplete());
    }
    let image = MachOImage::parse(&fixture()).unwrap();
    let mut p = GhidraProgram::from_macho_image("changed", &image);
    p32(&mut p.segments[0].data, 0x304, 0xd503201f);
    let f = HopperHybridObjcAnalyzerRs::new().analyze_function_zero_ipc(
        &mut p,
        "changed",
        0x1300,
        16,
        &[],
    );
    assert!(f.is_incomplete());
}
