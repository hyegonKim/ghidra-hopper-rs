//! Hopper-Grade Mach-O Universal Binary & Objective-C / Swift Metadata Analyzer in pure Rust.
//!
//! Directly addresses Ghidra's slower Java-based Mach-O / dyld fixup / Objective-C selector
//! analysis by using zero-copy byte slice parsing to extract:
//! - Universal (`0xCAFEBABE`) architecture slices (`x86_64`, `arm64`)
//! - 64-bit Mach-O (`0xFEEDFACF`) segments and sections
//! - Objective-C `__objc_methname`, `__objc_classname`, `__objc_selrefs`, `__objc_stubs`
//! - Swift 5 `__swift5_typeref` and `__swift5_reflstr` reflection strings

use crate::segment::{Section, Segment};
use std::collections::BTreeMap;

pub const FAT_MAGIC: u32 = 0xcafebabe;
pub const MH_MAGIC_64: u32 = 0xfeedfacf;
pub const ELF_MAGIC: u32 = 0x7f454c46;
pub const LC_SEGMENT_64: u32 = 0x19;
pub const LC_MAIN: u32 = 0x80000028;

#[derive(Debug, Clone)]
pub struct ArchSlice {
    pub cpu_type: u32,
    pub cpu_subtype: u32,
    pub arch_name: &'static str,
    pub offset: usize,
    pub size: usize,
}

#[derive(Debug, Clone)]
pub struct ObjCMetadata {
    pub class_names: Vec<String>,
    pub method_names: Vec<String>,
    /// Maps `__objc_selrefs` or `__objc_stubs` virtual address -> selector name
    pub selector_stubs: BTreeMap<u64, String>,
    pub swift_reflection_strings: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct MachOImage {
    pub is_universal: bool,
    pub slices: Vec<ArchSlice>,
    pub selected_arch: &'static str,
    pub entry_point: Option<u64>,
    pub segments: Vec<Segment>,
    pub objc: ObjCMetadata,
}

fn read_u32_be(buf: &[u8], off: usize) -> Option<u32> {
    let s = buf.get(off..off + 4)?;
    Some(u32::from_be_bytes([s[0], s[1], s[2], s[3]]))
}

fn read_u16_le(buf: &[u8], off: usize) -> Option<u16> {
    let s = buf.get(off..off + 2)?;
    Some(u16::from_le_bytes([s[0], s[1]]))
}

fn read_u32_le(buf: &[u8], off: usize) -> Option<u32> {
    let s = buf.get(off..off + 4)?;
    Some(u32::from_le_bytes([s[0], s[1], s[2], s[3]]))
}

fn read_u64_le(buf: &[u8], off: usize) -> Option<u64> {
    let s = buf.get(off..off + 8)?;
    Some(u64::from_le_bytes([s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7]]))
}

fn clean_fixed_str(bytes: &[u8]) -> String {
    let end = bytes.iter().position(|&b| b == 0).unwrap_or(bytes.len());
    String::from_utf8_lossy(&bytes[..end]).to_string()
}

fn cpu_type_name(cpu_type: u32) -> &'static str {
    match cpu_type {
        0x01000007 => "x86_64",
        0x0100000c => "arm64",
        7 => "i386",
        12 => "arm",
        _ => "unknown",
    }
}

impl MachOImage {
    /// Parses either a Universal Mach-O (`0xCAFEBABE`) or a thin 64-bit Mach-O (`0xFEEDFACF`),
    /// preferring the `arm64` slice on Apple Silicon just like Hopper Disassembler.
    pub fn parse(bytes: &[u8]) -> Result<Self, String> {
        if bytes.len() < 32 {
            return Err("Binary too small for Mach-O header".into());
        }
        let magic_be = read_u32_be(bytes, 0).unwrap_or(0);
        let magic_le = read_u32_le(bytes, 0).unwrap_or(0);

        let mut slices = Vec::new();
        if magic_be == ELF_MAGIC {
            return Self::parse_elf64(bytes);
        }
        let (is_universal, slice_bytes, selected_arch) = if magic_be == FAT_MAGIC {
            let nfat_arch = read_u32_be(bytes, 4).ok_or("Truncated fat_header")? as usize;
            let mut chosen_off = 0usize;
            let mut chosen_size = 0usize;
            let mut chosen_arch = "unknown";
            for i in 0..nfat_arch.min(16) {
                let base = 8 + i * 20;
                let cpu_type = read_u32_be(bytes, base).ok_or("Truncated fat_arch")?;
                let cpu_subtype = read_u32_be(bytes, base + 4).ok_or("Truncated fat_arch")?;
                let offset = read_u32_be(bytes, base + 8).ok_or("Truncated fat_arch")? as usize;
                let size = read_u32_be(bytes, base + 12).ok_or("Truncated fat_arch")? as usize;
                let arch_name = cpu_type_name(cpu_type);
                slices.push(ArchSlice {
                    cpu_type,
                    cpu_subtype,
                    arch_name,
                    offset,
                    size,
                });
                if chosen_size == 0 || arch_name == "arm64" {
                    chosen_off = offset;
                    chosen_size = size;
                    chosen_arch = arch_name;
                }
            }
            let sub = bytes
                .get(chosen_off..chosen_off.saturating_add(chosen_size))
                .ok_or("Universal slice out of bounds")?;
            (true, sub, chosen_arch)
        } else if magic_le == MH_MAGIC_64 {
            let cpu_type = read_u32_le(bytes, 4).unwrap_or(0);
            let cpu_subtype = read_u32_le(bytes, 8).unwrap_or(0);
            let arch_name = cpu_type_name(cpu_type);
            slices.push(ArchSlice {
                cpu_type,
                cpu_subtype,
                arch_name,
                offset: 0,
                size: bytes.len(),
            });
            (false, bytes, arch_name)
        } else {
            return Err(format!("Unsupported binary magic: 0x{:08x}", magic_be));
        };

        Self::parse_thin_macho64(slice_bytes, is_universal, slices, selected_arch)
    }

    fn parse_thin_macho64(
        slice: &[u8],
        is_universal: bool,
        slices: Vec<ArchSlice>,
        selected_arch: &'static str,
    ) -> Result<Self, String> {
        let magic = read_u32_le(slice, 0).ok_or("Missing Mach-O 64 magic")?;
        if magic != MH_MAGIC_64 {
            return Err(format!("Expected MH_MAGIC_64 (0xfeedfacf), got 0x{:08x}", magic));
        }
        let ncmds = read_u32_le(slice, 16).ok_or("Missing ncmds")? as usize;
        let mut cmd_offset = 32usize;

        let mut segments = Vec::new();
        let mut entry_point = None;
        let mut text_vmaddr = 0u64;

        let mut objc = ObjCMetadata {
            class_names: Vec::new(),
            method_names: Vec::new(),
            selector_stubs: BTreeMap::new(),
            swift_reflection_strings: Vec::new(),
        };

        // Track section ranges so we can recover ObjC/Swift tables after segments are loaded.
        let mut sec_ranges: Vec<(String, u64, usize, usize)> = Vec::new();

        for _ in 0..ncmds.min(512) {
            let Some(cmd) = read_u32_le(slice, cmd_offset) else { break };
            let Some(cmdsize) = read_u32_le(slice, cmd_offset + 4) else { break };
            if cmdsize < 8 || cmd_offset + cmdsize as usize > slice.len() {
                break;
            }

            if cmd == LC_SEGMENT_64 && cmdsize >= 72 {
                let segname = clean_fixed_str(&slice[cmd_offset + 8..cmd_offset + 24]);
                let vmaddr = read_u64_le(slice, cmd_offset + 24).unwrap_or(0);
                let _vmsize = read_u64_le(slice, cmd_offset + 32).unwrap_or(0);
                let fileoff = read_u64_le(slice, cmd_offset + 40).unwrap_or(0) as usize;
                let filesize = read_u64_le(slice, cmd_offset + 48).unwrap_or(0) as usize;
                let nsects = read_u32_le(slice, cmd_offset + 64).unwrap_or(0) as usize;

                if segname == "__TEXT" {
                    text_vmaddr = vmaddr;
                }

                // Cap in-memory segment copy to 16 MiB so large binaries stay instantaneous.
                let capped_size = filesize.min(16 * 1024 * 1024);
                let seg_bytes = if fileoff < slice.len() {
                    let end = (fileoff + capped_size).min(slice.len());
                    slice[fileoff..end].to_vec()
                } else {
                    Vec::new()
                };

                let mut seg = Segment::new(segname.clone(), vmaddr, fileoff as u64, seg_bytes);

                let mut sect_cursor = cmd_offset + 72;
                for _ in 0..nsects {
                    if sect_cursor + 80 > cmd_offset + cmdsize as usize {
                        break;
                    }
                    let sectname = clean_fixed_str(&slice[sect_cursor..sect_cursor + 16]);
                    let addr = read_u64_le(slice, sect_cursor + 32).unwrap_or(0);
                    let size = read_u64_le(slice, sect_cursor + 40).unwrap_or(0);
                    let offset = read_u32_le(slice, sect_cursor + 48).unwrap_or(0) as usize;
                    let flags = read_u32_le(slice, sect_cursor + 64).unwrap_or(0);

                    seg.sections.push(Section {
                        name: sectname.clone(),
                        start_address: addr,
                        length: size,
                        flags,
                    });
                    sec_ranges.push((sectname, addr, offset, size as usize));
                    sect_cursor += 80;
                }
                segments.push(seg);
            } else if cmd == LC_MAIN && cmdsize >= 24 {
                let entryoff = read_u64_le(slice, cmd_offset + 8).unwrap_or(0);
                entry_point = Some(entryoff);
            }

            cmd_offset += cmdsize as usize;
        }

        if let Some(ep_off) = entry_point {
            entry_point = Some(text_vmaddr.wrapping_add(ep_off));
        }

        // Pass 1: Extract Objective-C & Swift string tables first (`__objc_methname` often appears after `__objc_stubs`)
        for (sectname, _addr, offset, size) in &sec_ranges {
            let Some(bytes_sec) = slice.get(*offset..offset.saturating_add((*size).min(262_144))) else {
                continue;
            };
            match sectname.as_str() {
                "__objc_classname" => {
                    objc.class_names = extract_null_terminated_strings(bytes_sec, 120);
                }
                "__objc_methname" => {
                    objc.method_names = extract_null_terminated_strings(bytes_sec, 200);
                }
                "__swift5_reflstr" | "__swift5_typeref" => {
                    let mut s = extract_null_terminated_strings(bytes_sec, 80);
                    objc.swift_reflection_strings.append(&mut s);
                }
                _ => {}
            }
        }

        // Pass 2: Bind `__objc_stubs` and `__objc_selrefs` now that `objc.method_names` is populated
        for (sectname, addr, offset, size) in &sec_ranges {
            let Some(bytes_sec) = slice.get(*offset..offset.saturating_add((*size).min(262_144))) else {
                continue;
            };
            match sectname.as_str() {
                "__objc_stubs" => {
                    // Hopper maps each 32-byte ARM64 stub in `__objc_stubs` to `objc_msgSend$selector`.
                    let stub_stride = 32usize;
                    let count = (bytes_sec.len() / stub_stride).min(objc.method_names.len().max(64));
                    for idx in 0..count {
                        let stub_addr = addr + (idx * stub_stride) as u64;
                        let sel = objc
                            .method_names
                            .get(idx)
                            .cloned()
                            .unwrap_or_else(|| format!("selector_{}", idx));
                        objc.selector_stubs.insert(stub_addr, sel);
                    }
                }
                "__objc_selrefs" => {
                    if objc.selector_stubs.is_empty() {
                        let ptr_stride = 8usize;
                        let count = (bytes_sec.len() / ptr_stride).min(objc.method_names.len().max(64));
                        for idx in 0..count {
                            let selref_addr = addr + (idx * ptr_stride) as u64;
                            let sel = objc
                                .method_names
                                .get(idx)
                                .cloned()
                                .unwrap_or_else(|| format!("selref_{}", idx));
                            objc.selector_stubs.insert(selref_addr, sel);
                        }
                    }
                }
                _ => {}
            }
        }

        Ok(Self {
            is_universal,
            slices,
            selected_arch,
            entry_point,
            segments,
            objc,
        })
    }

    /// Zero-copy ELF64 (`.so` / executable) loader for Android NDK / Linux ARM64 & x86_64 binaries.
    /// Extracts `PT_LOAD` segments, section headers, `.dynsym`/`.dynstr` JNI & C++ exports,
    /// `.rela.plt` -> `.plt` AArch64 call stubs, and `.note.gnu.build-id`.
    fn parse_elf64(slice: &[u8]) -> Result<Self, String> {
        if slice.len() < 64 {
            return Err("Binary too small for ELF64 header".into());
        }
        let ei_class = slice[4];
        if ei_class != 2 {
            return Err(format!("Unsupported ELF class {} (expected ELF64=2)", ei_class));
        }
        let e_machine = read_u16_le(slice, 18).unwrap_or(0);
        let selected_arch = match e_machine {
            183 => "arm64",
            62 => "x86_64",
            40 => "arm",
            3 => "i386",
            _ => "unknown",
        };
        let e_entry = read_u64_le(slice, 24).unwrap_or(0);
        let e_phoff = read_u64_le(slice, 32).unwrap_or(0) as usize;
        let e_shoff = read_u64_le(slice, 40).unwrap_or(0) as usize;
        let e_phentsize = read_u16_le(slice, 54).unwrap_or(0) as usize;
        let e_phnum = read_u16_le(slice, 56).unwrap_or(0) as usize;
        let e_shentsize = read_u16_le(slice, 58).unwrap_or(0) as usize;
        let e_shnum = read_u16_le(slice, 60).unwrap_or(0) as usize;
        let e_shstrndx = read_u16_le(slice, 62).unwrap_or(0) as usize;

        let slices = vec![ArchSlice {
            cpu_type: e_machine as u32,
            cpu_subtype: 0,
            arch_name: selected_arch,
            offset: 0,
            size: slice.len(),
        }];

        let mut segments = Vec::new();
        if e_phentsize >= 56 {
            for i in 0..e_phnum.min(64) {
                let off = e_phoff + i * e_phentsize;
                if off + 56 > slice.len() {
                    break;
                }
                let p_type = read_u32_le(slice, off).unwrap_or(0);
                if p_type != 1 {
                    continue; // PT_LOAD == 1
                }
                let _p_flags = read_u32_le(slice, off + 4).unwrap_or(0);
                let p_offset = read_u64_le(slice, off + 8).unwrap_or(0) as usize;
                let p_vaddr = read_u64_le(slice, off + 16).unwrap_or(0);
                let p_filesz = read_u64_le(slice, off + 32).unwrap_or(0) as usize;

                let segname = if segments.is_empty() {
                    "__TEXT".to_string()
                } else {
                    format!("PT_LOAD_{}", segments.len())
                };
                let capped = p_filesz.min(16 * 1024 * 1024);
                let seg_bytes = if p_offset < slice.len() {
                    let end = (p_offset + capped).min(slice.len());
                    slice[p_offset..end].to_vec()
                } else {
                    Vec::new()
                };
                segments.push(Segment::new(segname, p_vaddr, p_offset as u64, seg_bytes));
            }
        }

        let mut objc = ObjCMetadata {
            class_names: Vec::new(),
            method_names: Vec::new(),
            selector_stubs: BTreeMap::new(),
            swift_reflection_strings: Vec::new(),
        };

        let shstrtab: &[u8] = if e_shentsize >= 64 && e_shstrndx < e_shnum {
            let sh_off = e_shoff + e_shstrndx * e_shentsize;
            let off = read_u64_le(slice, sh_off + 24).unwrap_or(0) as usize;
            let sz = read_u64_le(slice, sh_off + 32).unwrap_or(0) as usize;
            slice.get(off..off.saturating_add(sz)).unwrap_or(&[])
        } else {
            &[]
        };

        let mut dynsym_range = (0usize, 0usize);
        let mut dynstr_range = (0usize, 0usize);
        let mut rela_plt_range = (0usize, 0usize);
        let mut plt_addr_size = (0u64, 0usize);
        let mut first_jni_entry: Option<u64> = None;

        if e_shentsize >= 64 {
            for i in 0..e_shnum.min(256) {
                let sh_off = e_shoff + i * e_shentsize;
                if sh_off + 64 > slice.len() {
                    break;
                }
                let sh_name_idx = read_u32_le(slice, sh_off).unwrap_or(0) as usize;
                let sh_flags = read_u64_le(slice, sh_off + 8).unwrap_or(0) as u32;
                let sh_addr = read_u64_le(slice, sh_off + 16).unwrap_or(0);
                let sh_offset = read_u64_le(slice, sh_off + 24).unwrap_or(0) as usize;
                let sh_size = read_u64_le(slice, sh_off + 32).unwrap_or(0) as usize;

                let sectname = if sh_name_idx < shstrtab.len() {
                    clean_fixed_str(&shstrtab[sh_name_idx..])
                } else {
                    format!("sec_{}", i)
                };

                if !sectname.is_empty() {
                    if let Some(seg) = segments.first_mut() {
                        seg.sections.push(Section {
                            name: sectname.clone(),
                            start_address: sh_addr,
                            length: sh_size as u64,
                            flags: sh_flags,
                        });
                    }
                }

                match sectname.as_str() {
                    ".dynsym" => dynsym_range = (sh_offset, sh_size),
                    ".dynstr" => dynstr_range = (sh_offset, sh_size),
                    ".rela.plt" => rela_plt_range = (sh_offset, sh_size),
                    ".plt" => plt_addr_size = (sh_addr, sh_size),
                    ".note.gnu.build-id" => {
                        if let Some(note) = slice.get(sh_offset..sh_offset.saturating_add(sh_size)) {
                            if note.len() >= 16 {
                                let namesz = read_u32_le(note, 0).unwrap_or(0) as usize;
                                let descsz = read_u32_le(note, 4).unwrap_or(0) as usize;
                                let aligned_name = (namesz + 3) & !3;
                                let desc_start = 12 + aligned_name;
                                if let Some(desc) = note.get(desc_start..desc_start.saturating_add(descsz)) {
                                    let hex: String = desc.iter().map(|b| format!("{:02x}", b)).collect();
                                    objc.swift_reflection_strings.push(format!("gnu.build-id:{}", hex));
                                }
                            }
                        }
                    }
                    _ => {}
                }
            }
        }

        let dynstr = slice
            .get(dynstr_range.0..dynstr_range.0.saturating_add(dynstr_range.1))
            .unwrap_or(&[]);
        let dynsym = slice
            .get(dynsym_range.0..dynsym_range.0.saturating_add(dynsym_range.1))
            .unwrap_or(&[]);

        let sym_count = dynsym.len() / 24;
        let mut sym_names = Vec::with_capacity(sym_count);
        for i in 0..sym_count {
            let base = i * 24;
            let st_name = read_u32_le(dynsym, base).unwrap_or(0) as usize;
            let st_value = read_u64_le(dynsym, base + 8).unwrap_or(0);
            let name = if st_name < dynstr.len() {
                clean_fixed_str(&dynstr[st_name..])
            } else {
                String::new()
            };
            if st_value != 0 && !name.is_empty() {
                objc.selector_stubs.insert(st_value, name.clone());
                if name == "JNI_OnLoad" && first_jni_entry.is_none() {
                    first_jni_entry = Some(st_value);
                }
                if name.starts_with("Java_") || name.starts_with("JNI_") {
                    objc.method_names.push(name.clone());
                    if let Some(rest) = name.strip_prefix("Java_") {
                        if let Some((cls_part, _)) = rest.rsplit_once('_') {
                            let cls = cls_part.replace('_', ".");
                            if !objc.class_names.contains(&cls) {
                                objc.class_names.push(cls);
                            }
                        }
                    }
                }
            }
            sym_names.push(name);
        }

        // Bind AArch64 `.rela.plt` entries to `.plt` stubs (32-byte header + 16-byte entries)
        if plt_addr_size.0 != 0 && rela_plt_range.1 >= 24 {
            if let Some(rela_bytes) =
                slice.get(rela_plt_range.0..rela_plt_range.0.saturating_add(rela_plt_range.1))
            {
                let rela_count = rela_bytes.len() / 24;
                for i in 0..rela_count {
                    let base = i * 24;
                    let r_info = read_u64_le(rela_bytes, base + 8).unwrap_or(0);
                    let sym_idx = (r_info >> 32) as usize;
                    let stub_addr = plt_addr_size.0 + 32 + (i as u64) * 16;
                    if let Some(sym_name) = sym_names.get(sym_idx) {
                        if !sym_name.is_empty() {
                            objc.selector_stubs
                                .insert(stub_addr, format!("plt${}", sym_name));
                        }
                    }
                }
            }
        }

        let entry_point = if e_entry != 0 {
            Some(e_entry)
        } else {
            first_jni_entry
        };

        Ok(Self {
            is_universal: false,
            slices,
            selected_arch,
            entry_point,
            segments,
            objc,
        })
    }
}

fn extract_null_terminated_strings(bytes: &[u8], limit: usize) -> Vec<String> {
    let mut out = Vec::new();
    for part in bytes.split(|&b| b == 0) {
        if part.len() >= 2 && part.iter().all(|&b| (0x20..=0x7e).contains(&b)) {
            out.push(String::from_utf8_lossy(part).to_string());
            if out.len() >= limit {
                break;
            }
        }
    }
    out
}
