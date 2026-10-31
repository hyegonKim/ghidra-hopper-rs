"""Compare the unchanged 172-entry corpus at identical instruction budgets.

Print a compact JSON artifact; callers persist stdout to verification.json.
Original application binaries are analyzed statically, never executed here.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

p = argparse.ArgumentParser()
for name in ["baseline", "candidate", "hopper", "elf-dir", "native", "reference"]:
    p.add_argument("--" + name, type=Path, required=True)
a = p.parse_args()
root = Path(__file__).resolve().parent
prior = json.loads((root.parent / "wide/verification.json").read_text())
paths = {"hopper": a.hopper, "counter": a.elf_dir / "libdatastore_shared_counter.so"}
paths.update({name: a.elf_dir / name for name in prior["inputs_sha256"] if name not in paths})


def run(command):
    return subprocess.run([str(x) for x in command], text=True, capture_output=True, timeout=120)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


digests = {name: sha(path) for name, path in paths.items()}
assert digests == prior["inputs_sha256"]
assert sha(a.baseline) == prior["candidate_sha256"] == "6d7f848b6d96f68f9c148b1ff98ad945220c1ef458a146cca048198ef6373059"
entries = prior["entries"]
assert len(entries) == 172
old_rows = {(row[0], row[1]): row for row in prior["comparisons"]}


def analyze(exe, path, pc, budget, profile=None):
    command = [exe, "decompile", path, "conditional_compare_validation", pc, budget]
    if profile is not None:
        command += ["--jni-runtime", profile]
    result = run(command)
    rows = re.findall(r"^0x([0-9a-f]+)\s+\[[^\]]+\]\s+((?:[0-9a-f]{2}\s+){4})(\S+)", result.stdout, re.M)
    assert result.returncode in [0, 2] and rows, (path, pc, result.returncode, result.stderr[:500])
    work = re.search(r"^Instruction work: (\d+)", result.stdout, re.M)
    out = {"decoded": len(rows), "work": int(work[1]), "exit": result.returncode,
           "unsupported": [[hex(int(pc, 16)), hex(int.from_bytes(bytes.fromhex(word), "little"))]
                           for pc, word, op in rows if op == "inst.arm64"],
           "indirect": re.findall(r"goto \*(\w+);", result.stdout),
           "objc_calls": len(re.findall(r"ObjcMessage \{", result.stdout))}
    assert out["decoded"] <= out["work"] <= budget
    return out, result.stdout


comparisons = []
summaries = {}
for index, entry in enumerate(entries):
    binary = entry["binary"]
    for budget in [128, 512, 2048]:
        before, _ = analyze(a.baseline, paths[binary], entry["entry"], budget)
        after, _ = analyze(a.candidate, paths[binary], entry["entry"], budget)
        old = old_rows[index, budget]
        # Reproduce the previous candidate, including exact stopping words.
        assert [before[k] for k in ["decoded", "work", "exit", "unsupported", "indirect", "objc_calls"]] == [old[n] for n in [3, 5, 7, 9, 11, 13]], (entry, budget, before, old)
        assert after["decoded"] >= before["decoded"], (entry, budget, before, after)
        assert before["exit"] != 0 or after["exit"] == 0, (entry, budget)
        if binary in ["hopper", "counter"]:
            assert before == after, (entry, budget, before, after)
        comparisons.append([index, budget, before["decoded"], after["decoded"], before["work"], after["work"],
                            before["exit"], after["exit"], before["unsupported"], after["unsupported"],
                            before["indirect"], after["indirect"], before["objc_calls"], after["objc_calls"]])
        group = summaries.setdefault(f"{binary}/{budget}", {"entries": 0, "before_supported": 0, "after_supported": 0, "before_decoded": 0, "after_decoded": 0})
        group["entries"] += 1
        for label, row in [("before", before), ("after", after)]:
            group[label + "_supported"] += int(row["exit"] == 0)
            group[label + "_decoded"] += row["decoded"]

jni = []
profiles = sorted((root.parent / "jni_runtime").glob("default-*.json")) + sorted((root.parent / "jni_runtime").glob("checkjni-*.json"))
assert len(profiles) == 4
for profile in profiles:
    for budget in [128, 512, 2048]:
        before, _ = analyze(a.baseline, paths["counter"], "0xd80", budget, profile)
        after, text = analyze(a.candidate, paths["counter"], "0xd80", budget, profile)
        assert before == after and after["exit"] == 0 and 'tailcall_runtime_jni("ThrowNew"' in text
        jni.append({"profile": profile.name, "budget": budget, "decoded": after["decoded"], "work": after["work"], "exit": 0})

native = run([sys.executable, root / "verify_native.py", "--native", a.native, "--reference", a.reference])
assert native.returncode == 0, native.stderr[:2000]
assert digests == {name: sha(path) for name, path in paths.items()}
result = {"baseline_commit": "37c847f85fa1bf4bffccf348dab2a16b0d5a552e", "baseline_sha256": sha(a.baseline),
          "candidate_sha256": sha(a.candidate), "inputs_sha256": digests, "entries": entries,
          "columns": prior["columns"], "comparisons": comparisons, "summaries": summaries,
          "native": json.loads(native.stdout), "jni_context_regressions": jni,
          "scope": "Same 172-entry corpus as validation/wide, at 128/512/2048 work budgets. Original apps/libraries statically analyzed; native ARM64 instruction fixtures executed. Existing ART captures replayed, no new Android runtime observations."}
print(json.dumps(result, separators=(",", ":")))
