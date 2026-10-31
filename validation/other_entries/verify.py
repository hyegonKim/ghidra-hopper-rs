"""Portable same-input/budget survey plus native ARM64/IR differential checks.

Inputs are supplied explicitly; commercial/Android input binaries and compiled
libraries are not redistributed. Output is JSON on stdout, without full logs.
"""
import argparse
import ctypes
import hashlib
import json
import re
import struct
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
for option in ['baseline', 'candidate', 'hopper', 'elf', 'native', 'reference']:
    parser.add_argument('--' + option, required=True, type=Path)
args = parser.parse_args()
args = argparse.Namespace(**{k: v.resolve() for k, v in vars(args).items()})

def run(command, **kwargs):
    return subprocess.run([str(a) for a in command], capture_output=True, text=True, timeout=40, **kwargs)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def entries():
    b = args.hopper.read_bytes()
    assert b[:4] == bytes.fromhex('cafebabe')
    count = struct.unpack_from('>I', b, 4)[0]
    _, _, offset, size, _ = next(struct.unpack_from('>IIIII', b, 8 + n * 20) for n in range(count) if struct.unpack_from('>I', b, 8 + n * 20)[0] == 0x100000c)
    b = b[offset:offset + size]
    base = start_data = None
    command = 32
    for _ in range(struct.unpack_from('<I', b, 16)[0]):
        cmd, size = struct.unpack_from('<II', b, command)
        if cmd == 0x26: start_data = struct.unpack_from('<II', b, command + 8)
        if cmd == 0x19 and b[command + 8:command + 24].split(b'\0')[0] == b'__TEXT': base = struct.unpack_from('<Q', b, command + 24)[0]
        command += size
    assert base is not None and start_data is not None
    cursor, length = start_data
    end = cursor + length
    pc = base
    out = []
    while cursor < end:
        delta = shift = 0
        while True:
            value = b[cursor]; cursor += 1
            delta |= (value & 127) << shift
            shift += 7
            if not value & 128: break
        if not delta: break
        pc += delta
        out.append(('hopper', pc, hex(pc), 'control' if pc == 0x100002ddc else 'function-start'))
    b = args.elf.read_bytes()
    assert b[:6] == b'\x7fELF\x02\x01' and struct.unpack_from('<H', b, 18)[0] == 183
    shoff = struct.unpack_from('<Q', b, 40)[0]
    stride, count = struct.unpack_from('<HH', b, 58)
    sections = [struct.unpack_from('<IIQQQQIIQQ', b, shoff + n * stride) for n in range(count)]
    for section in sections:
        if section[1] != 11: continue
        strings = sections[section[6]]
        names = b[strings[4]:strings[4] + strings[5]]
        for n in range(section[5] // section[9]):
            name, info, _, defined, address, _ = struct.unpack_from('<IBBHQQ', b, section[4] + n * section[9])
            if info & 15 == 2 and defined and address:
                out.append(('elf', address, names[name:].split(b'\0')[0].decode(), 'export'))
    out += [('elf', 0xd30, 'previous .text entry', 'control'),
            ('elf', 0xf10, 'stack-check failure block', 'failure-block'),
            ('elf', 0xff0, 'atomic increment helper', 'direct-call-target')]
    assert len(out) == 29
    return out

def analyze(executable, path, address, budget):
    p = run([executable, 'decompile', path, 'entry_survey', hex(address), budget])
    rows = re.findall(r'^0x([0-9a-f]+)\s+\[[^\]]+\]\s+((?:[0-9a-f]{2}\s+){4})(\S+)', p.stdout, re.M)
    assert rows and p.returncode in [0, 2], p.stderr
    summary = {'decoded': len(rows), 'exit': p.returncode,
               'unsupported': [{'address': hex(int(a, 16)), 'word': hex(int.from_bytes(bytes.fromhex(w), 'little'))} for a, w, m in rows if m == 'inst.arm64'],
               'indirect_registers': re.findall(r'goto \*(\w+);', p.stdout),
               'nonreturning_calls': re.findall(r'call_noreturn\("([^"]+)"', p.stdout)}
    summary['unverified_continuations'] = re.findall(r'fall-through to (0x[0-9a-f]+) crosses', p.stdout)
    return summary, {int(a, 16) for a, _, _ in rows}, p.stdout

digests = {name: sha(getattr(args, name)) for name in ['hopper', 'elf']}
assert digests['hopper'] == 'dad6f886261fad0d4cdd01aee6fcf57439c60d7b5c54e62fc97f0180116690e0'
assert digests['elf'] == 'd3e48717c9aa147e0ab21063ba0e8e0211cabf8bf40b222640829519edbf58e1'
comparisons = []
for binary, address, name, kind in entries():
    for budget in [128, 512, 2048]:
        before, old_addresses, _ = analyze(args.baseline, getattr(args, binary), address, budget)
        after, new_addresses, output = analyze(args.candidate, getattr(args, binary), address, budget)
        assert after['decoded'] <= budget
        if kind == 'control' and binary == 'elf':
            assert before['decoded'] == after['decoded'] and before['exit'] == after['exit']
        if binary == 'hopper' and address == 0x100002ddc and budget == 2048:
            assert before['decoded'] == 1124 and after['decoded'] == 1121 and before['exit'] == 0 and after['exit'] == 2
            assert 0x100003f60 not in new_addresses and after['unverified_continuations'] == ['0x100003f60']
        if binary == 'elf' and address == 0xe54:
            assert before['decoded'] == 6 and after['decoded'] == 48 and after['exit'] == 0
            assert 'read_thread_pointer(TPIDR_EL0)' in output and 'select_u64' in output
            assert after['nonreturning_calls'] == ['__stack_chk_fail']
            assert max(new_addresses) == 0xf10  # no spill into next JNI function
        if binary == 'elf' and address == 0xfc0:
            assert before['decoded'] == 1 and after['decoded'] == 2 and after['exit'] == 0
            assert 'atomic_load_acquire_u32' in output
        if binary == 'elf' and address == 0xf10:
            assert before['decoded'] == 7 and after['decoded'] == 1 and after['exit'] == 0
        if binary == 'elf' and address == 0xff0:
            assert after['exit'] == 2 and {u['word'] for u in after['unsupported']} == {'0xb8e00020', '0x885ffc20'}
        if binary == 'elf' and address == 0xd80:
            assert after['exit'] == 2 and after['indirect_registers'] == ['x3']
        comparisons.append({'binary': binary, 'entry': hex(address), 'name': name, 'kind': kind, 'budget': budget,
                            'before': before, 'after': after, 'removed_addresses': [hex(a) for a in sorted(old_addresses - new_addresses)]})
assert digests == {name: sha(getattr(args, name)) for name in digests}

symbols = run(['nm', '-n', args.native])
assert symbols.returncode == 0
symbols = {name: int(address, 16) for address, name in re.findall(r'^([0-9a-fA-F]+) T (\S+)$', symbols.stdout, re.M)}
disasm = run(['/usr/bin/objdump', '-d', args.native])
words = {int(address, 16): int(word, 16) for address, word in re.findall(r'^\s*([0-9a-f]+):\s+([0-9a-f]{8})\s', disasm.stdout, re.M)}
library = ctypes.CDLL(str(args.native))
mask = (1 << 64) - 1
requests, expected = [], []
native_counts = {}

def native(name, *values):
    f = getattr(library, name)
    f.argtypes = [ctypes.c_uint64] * len(values)
    f.restype = ctypes.c_uint64
    native_counts[name.split('_')[0]] = native_counts.get(name.split('_')[0], 0) + 1
    return f(*values)

def case(name, regs, changes, instruction_offset=0, flags=0, memory=None, thread=0, reads=0, acquires=0):
    registers = [0] * 32
    registers[31] = 0x777788889999aaa0
    for index, value in regs.items(): registers[index] = value
    result = list(registers)
    for index, value in changes.items(): result[index] = value
    row = {'word': words[symbols['_' + name] + instruction_offset], 'regs': registers, 'flags': flags, 'thread_pointer': thread}
    if memory is not None: row.update({'memory_base': memory[0], 'bytes': memory[1]})
    requests.append(row)
    expected.append({'regs': result, 'reads': reads, 'acquires': acquires, 'flags': flags})

conditions = ['eq', 'ne', 'cs', 'cc', 'mi', 'pl', 'vs', 'vc', 'hi', 'ls', 'ge', 'lt', 'gt', 'le', 'al', 'nv']
for width in [32, 64]:
    for code, condition in enumerate(conditions):
        for flags in range(16):
            n, z, c, v = [bool(flags & bit) for bit in [8, 4, 2, 1]]
            decision = [z, not z, c, not c, n, not n, v, not v, c and not z, not c or z, n == v, n != v, not z and n == v, z or n != v, True, True][code]
            for a, b in [(0, mask), (0x8123456789abcdef, 0xfedcba9876543210), (1, 1 << 63)]:
                name = f'sel{width}_{condition}'
                wanted = (a if decision else b) % (1 << width)
                observed_flags = ctypes.c_uint64()
                assert native(name, a, b, flags << 28, ctypes.addressof(observed_flags)) == wanted
                assert observed_flags.value >> 28 == flags
                case(name, {0: a, 1: b}, {0: wanted}, instruction_offset=4, flags=flags)

values = [0, 1, 0x7fffffff, 0x80000000, 0xffffffff, 1 << 63, mask, 0x8123456789abcdef]
for width in [32, 64]:
    for shift in range(0, width, 16):
        for op in ['movk', 'movn']:
            name = f'{op}{width}_{shift}'
            for old in values:
                wanted = ((old & ~(65535 << shift)) | (0x6c69 << shift)) if op == 'movk' else ~(0x6c69 << shift)
                wanted %= 1 << width
                assert native(name, old) == wanted
                case(name, {0: old}, {0: wanted})

buffer = (ctypes.c_ubyte * 64)()
base = ctypes.addressof(buffer)
center = base + 32
for value in values:
    low = value & 0xffffffff
    wanted = low if low < 1 << 31 else low - (1 << 32)
    wanted &= mask
    for name in ['signed_offset', 'signed_unscaled', 'signed_pre', 'signed_post', 'signed_alias', 'signed_discard']:
        offset = -4 if name == 'signed_unscaled' else 0 if name == 'signed_post' else 4
        buffer[32 + offset:36 + offset] = low.to_bytes(4, 'little')
        updated = center + 4 if name in ['signed_pre', 'signed_post'] else center
        out = ctypes.c_uint64()
        assert native(name, center, ctypes.addressof(out)) == (42 if name == 'signed_discard' else wanted)
        if name not in ['signed_alias', 'signed_discard']: assert out.value == updated
        changed = {0: wanted} if name == 'signed_alias' else {} if name == 'signed_discard' else {0: updated, 2: wanted}
        case(name, {0: center}, changed, memory=(base, list(buffer)), reads=1)
    for width in [32, 64]:
        buffer[32:40] = value.to_bytes(8, 'little')
        wanted = value % (1 << width)
        name = f'acquire{width}'
        assert native(name, center) == wanted
        case(name, {0: center}, {0: wanted}, memory=(base, list(buffer)), reads=1, acquires=1)
    assert native('acquire_sp', value) == value
    case('acquire_sp', {0: value, 31: center}, {0: value}, instruction_offset=8, memory=(base, list(buffer)), reads=1, acquires=1)

thread = native('thread_read')
case('thread_read', {}, {0: thread}, thread=thread)
for value in values:
    assert native('thread_discard', value) == value
    case('thread_discard', {0: value}, {}, thread=thread)

reference = run([args.reference], input=json.dumps(requests))
assert reference.returncode == 0, reference.stderr
predictions = json.loads(reference.stdout)
assert len(predictions) == len(expected)
for n, (actual, wanted) in enumerate(zip(predictions, expected)):
    assert actual == wanted, (n, hex(requests[n]['word']), actual, wanted)
print(json.dumps({'baseline_sha256': sha(args.baseline), 'candidate_sha256': sha(args.candidate),
                  'input_sha256': digests, 'comparisons': comparisons,
                  'native_cases': sum(native_counts.values()), 'native_groups': native_counts,
                  'ir_differential_cases': len(requests)}, indent=2))
