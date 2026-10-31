"""Execute ARM64 instructions and compare registers/NZCV/SIMD with lifted IR.

Native MOVI integer lane forms and SMADDL/SMULL use assembler mnemonics.
The pre-existing D/2D MOVI regression fixtures use encoded bit masks.
"""
import argparse
import ctypes as C
import itertools
import json
from pathlib import Path
import platform
import random
import re
import subprocess

p = argparse.ArgumentParser()
p.add_argument("--native", type=Path, required=True)
p.add_argument("--reference", type=Path, required=True)
a = p.parse_args()
assert platform.machine() == "arm64"


def run(command, **kwargs):
    return subprocess.run([str(v) for v in command], text=True, capture_output=True, timeout=120, **kwargs)


r = run(["nm", "-n", a.native])
assert r.returncode == 0, r.stderr
symbols = {name: int(pc, 16) for pc, name in re.findall(r"^([0-9a-fA-F]+) T (\S+)$", r.stdout, re.M)}
r = run(["/usr/bin/objdump", "-d", a.native])
assert r.returncode == 0, r.stderr
words = {int(pc, 16): int(word, 16) for pc, word in re.findall(r"^\s*([0-9a-f]+):\s+([0-9a-f]{8})\s", r.stdout, re.M)}
lib = C.CDLL(str(a.native.resolve()))
requests, expected, labels = [], [], []
counts = {"smaddl_smull": 0, "movi": 0}
checked = batches = fixtures = 0


def flush():
    global checked, batches
    if not requests:
        return
    r = run([a.reference], input=json.dumps(requests))
    assert r.returncode == 0, r.stderr[:2000]
    actual = json.loads(r.stdout)
    assert len(actual) == len(expected)
    for result, wanted, label in zip(actual, expected, labels):
        for field, value in wanted.items():
            if isinstance(value, dict):
                for index, item in value.items():
                    assert result[field][index] == item, (checked, label, field, index, result[field][index], item)
            else:
                assert result[field] == value, (checked, label, field, result[field], value)
        checked += 1
    batches += 1
    requests.clear()
    expected.clear()
    labels.clear()


def add(name, row, wanted, kind):
    row["word"] = words[symbols["_" + name + "_op"]]
    requests.append(row)
    expected.append(wanted)
    labels.append(name)
    counts[kind] += 1
    if len(requests) >= 4096:
        flush()


mask = (1 << 64) - 1
edges = [0, 1, 0x7fffffff, 0x80000000, 0xffffffff, 0xffffffff00000000,
         0x8000000000000001, 0xabcdef0180000000, mask]
addends = [0, mask, 1 << 63, 0x7fffffff00000000]
rng = random.Random(0x534d4144444c)
randoms = [(rng.getrandbits(64), rng.getrandbits(64), rng.getrandbits(64)) for _ in range(128)]
samples = [(x, y, c, flags) for flags in range(16) for x, y in itertools.product(edges, repeat=2) for c in addends]
samples += [(x, y, c, flags) for flags in [0, 15] for x, y, c in randoms]
for index in range(13):
    name = f"long_{index}"
    fn = getattr(lib, name)
    fn.argtypes = [C.c_uint64] * 5
    fn.restype = None
    fixtures += 1
    for x, y, c, flags in samples:
        out = (C.c_uint64 * 5)()
        pointer = C.addressof(out)
        fn(x, y, c, flags << 28, pointer)
        regs = [0] * 32
        regs[0:5] = [x, y, c, flags << 28, pointer]
        regs[31] = out[4]
        wanted = {"regs": {0: out[0], 1: out[1], 2: out[2], 3: flags << 28, 4: pointer, 31: out[4]},
                  "flags": out[3] >> 28, "reads": 0, "writes": 0}
        add(name, {"regs": regs, "flags": flags}, wanted, "smaddl_smull")

seeds = [[0x0123456789abcdef, 0xfedcba9876543210, 0x80000000ffffffff, mask],
         [mask, 0x8123456789abcdef, 0xdeadbeef01020304, 0x0123456789abcdef]]
for op in [0, 1]:
    for q in [0, 1]:
        for cmode in ([14] if op else [0, 2, 4, 6, 8, 10, 12, 13, 14]):
            for rd in [0, 31]:
                for imm in range(256):
                    name = f"vi_{op}_{q}_{cmode}_{rd}_{imm}"
                    fn = getattr(lib, name)
                    fn.argtypes = [C.c_uint64] * 2
                    fn.restype = None
                    fixtures += 1
                    for flags in [0, 15]:
                        for seed in seeds:
                            out = (C.c_uint64 * 6)(*seed, 0, 0)
                            pointer = C.addressof(out)
                            fn(flags << 28, pointer)
                            regs = [0] * 32
                            regs[0:2] = [flags << 28, pointer]
                            regs[31] = out[5]
                            add(name, {"regs": regs, "flags": flags, "vectors": {"0": seed[:2], "31": seed[2:]}},
                                {"regs": {0: flags << 28, 1: pointer, 31: out[5]},
                                 "vectors": {0: list(out[:2]), 31: list(out[2:4])},
                                 "flags": out[4] >> 28, "reads": 0, "writes": 0}, "movi")
flush()
assert fixtures == 10253
assert len([name for name in symbols if name.endswith("_op")]) == fixtures
print(json.dumps({"fixtures": fixtures, "native_cases": checked, "batches": batches, "counts": counts,
                  "smaddl_alias_forms": 13, "movi_integer_encodings": 10240,
                  "checks": "Signed W sources ignoring X upper bits, wrapping X addend, aliases/ZR/discard, GPR/SP/NZCV preservation, V0/V31 full 128-bit results, scalar upper clearing, all imm8/cmode/Q MOVI forms, no target memory access."}))
