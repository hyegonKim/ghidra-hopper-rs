"""Reproduce 29-entry/3-budget comparison and native ARM64 differential checks.
Original commercial/Android inputs and generated libraries are never committed.
"""
import argparse
import ctypes as C
import hashlib
import json
import platform
import re
import struct
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
for option in ["baseline", "candidate", "hopper", "elf", "native", "reference", "objc"]:
    parser.add_argument("--" + option, required=True, type=Path)
args = parser.parse_args()
args = argparse.Namespace(**{k: v.resolve() for k, v in vars(args).items()})

def run(command, **kwargs):
    return subprocess.run([str(x) for x in command], text=True, capture_output=True, timeout=90, **kwargs)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def entries():
    b = args.hopper.read_bytes()
    assert b[:4] == bytes.fromhex("cafebabe")
    count = struct.unpack_from(">I", b, 4)[0]
    _, _, offset, size, _ = next(struct.unpack_from(">IIIII", b, 8 + n * 20) for n in range(count)
                                 if struct.unpack_from(">I", b, 8 + n * 20)[0] == 0x100000c)
    b = b[offset:offset + size]
    base = start_data = None
    command = 32
    for _ in range(struct.unpack_from("<I", b, 16)[0]):
        cmd, size = struct.unpack_from("<II", b, command)
        if cmd == 0x26:
            start_data = struct.unpack_from("<II", b, command + 8)
        if cmd == 0x19 and b[command + 8:command + 24].split(b"\0")[0] == b"__TEXT":
            base = struct.unpack_from("<Q", b, command + 24)[0]
        command += size
    assert base is not None and start_data is not None
    cursor, length = start_data
    end = cursor + length
    pc = base
    out = []
    while cursor < end:
        delta = shift = 0
        while True:
            value = b[cursor]
            cursor += 1
            delta |= (value & 127) << shift
            shift += 7
            if not value & 128:
                break
        if not delta:
            break
        pc += delta
        out.append(("hopper", pc, hex(pc)))
    b = args.elf.read_bytes()
    assert b[:6] == b"\x7fELF\x02\x01" and struct.unpack_from("<H", b, 18)[0] == 183
    shoff = struct.unpack_from("<Q", b, 40)[0]
    stride, count = struct.unpack_from("<HH", b, 58)
    sections = [struct.unpack_from("<IIQQQQIIQQ", b, shoff + n * stride) for n in range(count)]
    for section in sections:
        if section[1] != 11:
            continue
        strings = sections[section[6]]
        names = b[strings[4]:strings[4] + strings[5]]
        for n in range(section[5] // section[9]):
            name, info, _, defined, address, _ = struct.unpack_from("<IBBHQQ", b, section[4] + n * section[9])
            if info & 15 == 2 and defined and address:
                out.append(("elf", address, names[name:].split(b"\0")[0].decode()))
    out += [("elf", 0xd30, "previous .text entry"), ("elf", 0xf10, "stack-check failure block"),
            ("elf", 0xff0, "atomic increment helper")]
    assert len(out) == 29
    return out

def analyze(executable, path, address, budget):
    p = run([executable, "decompile", path, "entry_survey", hex(address), budget])
    rows = re.findall(r"^0x([0-9a-f]+)\s+\[[^\]]+\]\s+((?:[0-9a-f]{2}\s+){4})(\S+)", p.stdout, re.M)
    assert rows and p.returncode in [0, 2], (address, p.stderr)
    work = re.search(r"^Instruction work: (\d+)", p.stdout, re.M)
    result = {
        "decoded": len(rows), "work": int(work[1]) if work else len(rows), "exit": p.returncode,
        "unsupported": [{"address": hex(int(a, 16)), "word": hex(int.from_bytes(bytes.fromhex(w), "little"))}
                        for a, w, m in rows if m == "inst.arm64"],
        "indirect_registers": re.findall(r"goto \*(\w+);", p.stdout),
        "unverified_continuations": re.findall(r"fall-through to (0x[0-9a-f]+) crosses", p.stdout),
        "proofs": [{"target": a, "work": int(w), "proven": v == "true"} for a, w, v in
                   re.findall(r"Nonreturn proof: (0x[0-9a-f]+), (\d+) instructions, proven=(true|false)", p.stdout)]
    }
    return result, {int(a, 16) for a, _, _ in rows}, p.stdout

digests = {name: sha(getattr(args, name)) for name in ["hopper", "elf"]}
assert digests == {
    "hopper": "dad6f886261fad0d4cdd01aee6fcf57439c60d7b5c54e62fc97f0180116690e0",
    "elf": "d3e48717c9aa147e0ab21063ba0e8e0211cabf8bf40b222640829519edbf58e1"}
assert sha(args.baseline) == "5589509b71a847d86a871c4d59597b30ce10c2e87131d58fa66b3b24703babae"
comparisons = []
for binary, address, name in entries():
    for budget in [128, 512, 2048]:
        before, old, _ = analyze(args.baseline, getattr(args, binary), address, budget)
        after, new, output = analyze(args.candidate, getattr(args, binary), address, budget)
        assert after["decoded"] <= after["work"] <= budget, (hex(address), after)
        if binary == "hopper" and address == 0x100002ddc and budget == 2048:
            assert (before["decoded"], before["exit"], after["decoded"], after["exit"], after["work"]) == (1121, 2, 1121, 0, 1945)
            assert after["proofs"] == [{"target": "0x100001740", "work": 824, "proven": True}]
            assert 0x100003f60 not in new
        if binary == "hopper" and address == 0x100002cf0 and budget in [512, 2048]:
            assert (after["decoded"], after["exit"], after["work"]) == ((59, 2, 512) if budget == 512 else (59, 0, 883))
            assert after["proofs"] == [{"target": "0x100001740", "work": 453 if budget == 512 else 824, "proven": budget == 2048}]
        if binary == "hopper" and address in [0x100000a58, 0x100001740, 0x1000025ec] and budget == 2048:
            counts = {0x100000a58: (7, 7), 0x100001740: (529, 824), 0x1000025ec: (34, 247)}
            assert (before["decoded"], after["decoded"]) == counts[address]
            assert before["exit"] == 2 and after["exit"] == 0
        if binary == "elf" and address == 0xff0:
            assert (before["decoded"], before["exit"], after["decoded"], after["exit"]) == (7, 2, 12, 0)
            assert "atomic_fetch_add" in output and "exclusive_monitor" in output
        if binary == "elf" and address == 0xd80:
            assert after["exit"] == 2 and after["indirect_registers"] == ["x3"]
        comparisons.append({"binary": binary, "entry": hex(address), "name": name, "budget": budget,
                            "before": before, "after": after,
                            "added": [hex(a) for a in sorted(new - old)], "removed": [hex(a) for a in sorted(old - new)]})
assert digests == {name: sha(getattr(args, name)) for name in digests}

assert platform.machine() == "arm64", "Native checks require an ARM64 Mac"
lse = run(["sysctl", "-n", "hw.optional.armv8_1_atomics"])
assert lse.returncode == 0 and lse.stdout.strip() == "1", "Native LDADD requires hardware LSE support"
sym = run(["nm", "-n", args.native])
assert sym.returncode == 0
symbols = {name: int(address, 16) for address, name in re.findall(r"^([0-9a-fA-F]+) T (\S+)$", sym.stdout, re.M)}
disasm = run(["/usr/bin/objdump", "-d", args.native])
assert disasm.returncode == 0
words = {int(address, 16): int(word, 16) for address, word in
         re.findall(r"^\s*([0-9a-f]+):\s+([0-9a-f]{8})\s", disasm.stdout, re.M)}
lib = C.CDLL(str(args.native))
mask = (1 << 64) - 1
requests, expected = [], []
counts = {}
def native(name, *values):
    f = getattr(lib, name)
    f.argtypes = [C.c_uint64] * len(values)
    f.restype = C.c_uint64
    counts[name.split("_")[0]] = counts.get(name.split("_")[0], 0) + 1
    return f(*values)

def request(name, regs, checks, flags=0, memory=None, vectors=None, sequence=False, **extra):
    registers = [0] * 32
    registers[31] = 0x777788889999aaa0
    for index, value in regs.items():
        registers[index] = value
    start = symbols["_" + name + "_op"]
    row = {"regs": registers, "flags": flags, **extra}
    if sequence:
        row["words"] = [words[a] for a in range(start, symbols["_" + name + "_end"], 4)] + [0xd65f03c0]
    else:
        row["word"] = words[start]
    if memory is not None:
        row.update(memory_base=memory[0], bytes=memory[1])
    if vectors:
        row["vectors"] = {str(k): v for k, v in vectors.items()}
    requests.append(row)
    expected.append({"flags": flags, **checks})

seed = [0x0123456789abcdef, 0xfedcba9876543210, 0x1122334455667788, 0x8877665544332211]
initial = (C.c_uint64 * 4)(*seed)
for full in [0, 1]:
    for imm in range(256):
        expanded = sum((255 if imm & (1 << n) else 0) << (n * 8) for n in range(8))
        wanted = [expanded, expanded if full else 0]
        for flags in [0, 5, 10, 15]:
            out = (C.c_uint64 * 4)()
            observed_flags = C.c_uint64()
            canary = 0xdeadbeef12345678
            name = f"vec{full}_{imm}"
            assert native(name, C.addressof(out), flags << 28, canary, C.addressof(observed_flags), C.addressof(initial)) == canary
            assert list(out) == wanted + seed[2:] and observed_flags.value >> 28 == flags
            request(name, {0: C.addressof(out), 2: canary},
                    {"vectors": {0: wanted, 1: seed[2:]}, "regs": {0: C.addressof(out), 2: canary}, "reads": 0, "writes": 0},
                    flags=flags, vectors={0: seed[:2], 1: seed[2:]})

for kind in ["load", "store"]:
    for mode in ["offset", "pre", "post"]:
        for flags in range(16):
            mem = (C.c_ubyte * 192)(*[(n * 17 + 3) % 256 for n in range(192)])
            base, original = C.addressof(mem), list(mem)
            pointer = base + 80
            data = (C.c_uint64 * 4)(*seed)
            observed_flags = C.c_uint64()
            name = f"pair_{kind}_{mode}"
            address = pointer + {"offset": 16, "pre": -32, "post": 0}[mode]
            returned = pointer + {"offset": 0, "pre": -32, "post": 32}[mode]
            assert native(name, pointer, C.addressof(data), flags << 28, C.addressof(observed_flags)) == returned
            assert observed_flags.value >> 28 == flags
            if kind == "load":
                wanted = [int.from_bytes(bytes(original[address-base+n:address-base+n+8]), "little") for n in [0, 8, 16, 24]]
                assert list(data) == wanted and list(mem) == original
                check = {"vectors": {0: wanted[:2], 1: wanted[2:]}, "reads": 2, "writes": 0}
            else:
                wanted = original[:]
                wanted[address-base:address-base+32] = b"".join(v.to_bytes(8, "little") for v in seed)
                assert list(mem) == wanted
                check = {"bytes": wanted, "reads": 0, "writes": 2}
            request(name, {0: pointer}, {"regs": {0: returned}, **check}, flags=flags, memory=(base, original),
                    vectors={0: seed[:2], 1: seed[2:]})

indices = {"uxtw": [0, 1, 3, 0xdeadbeef00000002, 0xffffffff00000001],
           "lsl": [0, 1, 3, mask, mask-1],
           "sxtw": [0, 1, 0xffffffff, 0xfffffffe, 0xaabbccdd00000003],
           "sxtx": [0, 1, 3, mask, mask-1]}
for kind, widths in [("load", [1, 2, 4, 8, 0]), ("store", [1, 2, 4, 8])]:
    for size in widths:
        width = size or 4
        for ext in indices:
            for scaled in [0, 1]:
                for index in indices[ext]:
                    for flags in [0, 5, 10, 15]:
                        mem = (C.c_ubyte * 192)(*[(n * 29 + 0x83) % 256 for n in range(192)])
                        base, original = C.addressof(mem), list(mem)
                        pointer = base + 80
                        extended = index & 0xffffffff if ext in ["uxtw", "sxtw"] else index
                        if ext == "sxtw" and extended & (1 << 31):
                            extended -= 1 << 32
                        if ext == "sxtx" and extended & (1 << 63):
                            extended -= 1 << 64
                        address = (pointer + extended * (width if scaled else 1)) & mask
                        offset = address - base
                        data = 0x8fedcba987654321
                        name = f"idx_{kind}_{size}_{ext}_{scaled}"
                        observed_flags = C.c_uint64()
                        result = native(name, pointer, index, data, C.addressof(observed_flags), flags << 28)
                        assert observed_flags.value >> 28 == flags
                        wanted_bytes = original[:]
                        if kind == "load":
                            value = int.from_bytes(bytes(original[offset:offset+width]), "little", signed=size == 0) & mask
                            assert result == value and list(mem) == original
                        else:
                            value = pointer
                            wanted_bytes[offset:offset+width] = (data % (1 << (width * 8))).to_bytes(width, "little")
                            assert result == value and list(mem) == wanted_bytes
                        request(name, {0: pointer, 1: index, 2: data},
                                {"regs": {0: value, 1: index, 2: data}, "bytes": wanted_bytes,
                                 "reads": int(kind == "load"), "writes": int(kind == "store")},
                                flags=flags, memory=(base, original))

values = [0, 1, 0x7fffffff, 0x80000000, 0xffffffff, 1 << 63, mask, 0x8123456789abcdef]
for width in [32, 64]:
    bits = (1 << width) - 1
    for old in values:
        for addend in [0, 1, mask]:
            for flags in [0, 5, 10, 15]:
                for order in ["plain", "a", "l", "al", "loop"]:
                    cell = C.c_uint64(old)
                    base = C.addressof(cell)
                    original = list(C.string_at(base, 8))
                    new_value = ((old & bits) + (addend & bits)) & bits
                    expected_bytes = original[:]
                    expected_bytes[:width//8] = new_value.to_bytes(width//8, "little")
                    observed_flags = C.c_uint64()
                    name = f"loop{width}" if order == "loop" else f"atomic{width}_{order}"
                    result = native(name, addend, base, flags << 28, C.addressof(observed_flags))
                    assert result == old & bits and list(C.string_at(base, 8)) == expected_bytes
                    assert observed_flags.value >> 28 == flags
                    checks = {"regs": {0: old & bits}, "bytes": expected_bytes, "reads": 1, "writes": 1,
                              "rmws": int(order != "loop"), "attempts": int(order == "loop"), "reservation": False}
                    request(name, {0: addend, 1: base}, checks, flags=flags, memory=(base, original), sequence=order == "loop")
    # CLREX must make the subsequent store-exclusive fail without a write.
    for old in values:
        cell = C.c_uint64(old)
        base = C.addressof(cell)
        original = list(C.string_at(base, 8))
        name = f"fail{width}"
        assert native(name, 123, base, 0) == 1 and list(C.string_at(base, 8)) == original
        request(name, {0: 123, 1: base}, {"regs": {0: 1, 2: old & bits}, "bytes": original,
                "attempts": 1, "writes": 0, "reads": 1, "reservation": False}, memory=(base, original), sequence=True)
    # Model-only adversarial schedules: spurious failures and a conflicting write.
    for failures in [1, 3]:
        for interference in [None, bits - 3]:
            old, addend, base = 7, 9, 0x2000
            read_value = old if interference is None else interference
            final = (read_value + addend) & bits
            attempts = failures + 1
            request(f"loop{width}", {0: addend, 1: base},
                    {"regs": {0: read_value}, "bytes": list(final.to_bytes(width//8, "little")),
                     "attempts": attempts, "reads": attempts, "writes": 1 + int(interference is not None),
                     "rmws": 0, "reservation": False},
                    memory=(base, list(old.to_bytes(width//8, "little"))), sequence=True,
                    forced_failures=failures, **({"interference": interference} if interference is not None else {}))

reference = run([args.reference], input=json.dumps(requests))
assert reference.returncode == 0, reference.stderr
actual = json.loads(reference.stdout)
assert len(actual) == len(expected)
for n, (row, wanted) in enumerate(zip(actual, expected)):
    for field, value in wanted.items():
        if field in ["regs", "vectors"]:
            for index, v in value.items():
                assert row[field][index] == v, (n, field, index, row[field][index], v)
        else:
            assert row[field] == value, (n, field, row[field], value)

stress = lib.run_stress
stress.argtypes = [C.c_uint64, C.c_uint32, C.c_uint32, C.POINTER(C.c_uint32), C.POINTER(C.c_uint32)]
stress.restype = C.c_int
stresses = []
for name in ["stress_lse", "stress_exclusive"]:
    workers, iterations = 4, 2000
    tickets = (C.c_uint32 * (workers * iterations))()
    final = C.c_uint32()
    address = C.cast(getattr(lib, name), C.c_void_p).value
    assert stress(address, workers, iterations, C.byref(final), tickets) == 0
    assert final.value == workers * iterations and sorted(tickets) == list(range(workers * iterations))
    stresses.append({"path": name, "workers": workers, "increments": final.value, "unique_old_values": len(set(tickets))})

objc = C.CDLL(str(args.objc))
objc.objc_probe.argtypes = [C.c_uint64]
objc.objc_probe.restype = C.c_uint64
for value in values:
    assert objc.objc_probe(value) == (value * 3 + 7) & mask
objc_disasm = run(["/usr/bin/objdump", "-d", args.objc])
stub = re.search(r"^([0-9a-f]+) <_objc_msgSend\$echo:>:", objc_disasm.stdout, re.M)
assert stub
objc_before, _, _ = analyze(args.baseline, args.objc, int(stub[1], 16), 32)
objc_after, _, objc_text = analyze(args.candidate, args.objc, int(stub[1], 16), 32)
assert (objc_before["exit"], objc_after["exit"], objc_after["decoded"]) == (2, 0, 5)
assert "_objc_msgSend" in objc_text and "selector" in objc_text
result = {"baseline_commit": "982c26f28bb8e3a05ede9502eb64892512697dd1",
          "sha256": {**digests, "baseline": sha(args.baseline), "candidate": sha(args.candidate)},
          "budgets": [128, 512, 2048], "entries": 29, "comparisons": comparisons,
          "native_cases": counts, "differential_cases": len(actual), "model_adversarial_cases": 8,
          "concurrent_native": stresses, "objc_native_calls": len(values),
          "objc_stub": {"before": objc_before, "after": objc_after}}
print(json.dumps(result, indent=2))
