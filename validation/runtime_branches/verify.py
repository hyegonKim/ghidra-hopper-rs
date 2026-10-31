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

p = argparse.ArgumentParser()
for name in ["baseline", "candidate", "hopper", "elf-dir"]:
    p.add_argument("--" + name, type=Path, required=True)
a = p.parse_args()
root = Path(__file__).resolve().parent
prior = json.loads((root.parent / "long_movi/verification.json").read_text())
paths = {"hopper": a.hopper, "counter": a.elf_dir / "libdatastore_shared_counter.so"}
paths.update({name: a.elf_dir / name for name in prior["inputs_sha256"] if name not in paths})


def run(command):
    return subprocess.run([str(x) for x in command], text=True, capture_output=True, timeout=120)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


digests = {name: sha(path) for name, path in paths.items()}
assert digests == prior["inputs_sha256"]
assert sha(a.baseline) == prior["candidate_sha256"] == "493cc79368e6fad68156ecaaa0af0b2eb8e3b71100be31504ce9cadd02f97f8e"
entries = prior["entries"]
assert len(entries) == 172
old_rows = {(row[0], row[1]): row for row in prior["comparisons"]}


def analyze(exe, path, pc, budget, profile=None):
    command = [exe, "decompile", path, "runtime_branches_validation", pc, budget]
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


raw_texts = {}
comparisons = []
summaries = {}
for index, entry in enumerate(entries):
    binary = entry["binary"]
    for budget in [128, 512, 2048]:
        before, raw = analyze(a.baseline, paths[binary], entry["entry"], budget)
        if (binary,entry["entry"]) in [("counter","0xd80"),("counter","0xd50"),("counter","0x10c0"),("libimage_processing_util_jni.so","0x719c")]:
            raw_texts[binary,entry["entry"],budget] = (before, raw)
        after, _ = analyze(a.candidate, paths[binary], entry["entry"], budget)
        old = old_rows[index, budget]
        # Reproduce the previous candidate, including exact stopping words.
        assert [before[k] for k in ["decoded", "work", "exit", "unsupported", "indirect", "objc_calls"]] == [old[n] for n in [3, 5, 7, 9, 11, 13]], (entry, budget, before, old)
        assert after["decoded"] >= before["decoded"], (entry, budget, before, after)
        assert before["exit"] != 0 or after["exit"] == 0, (entry, budget)
        # No runtime capture means identical static results for every input.
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

runtime = []
for profile in sorted(root.glob("*.json")):
    if profile.name == "verification.json": continue
    v = json.loads(profile.read_text())
    kind = profile.stem.rsplit("-", 1)[1]
    binary,entry,flag = {
        "throw": ("counter","0xd80","--jni-runtime"),
        "buffer": ("libimage_processing_util_jni.so","0x719c","--jni-runtime"),
        "callback": ("counter","0xd50","--branch-runtime"),
        "resolver": ("counter","0x10c0","--branch-runtime"),
    }[kind]
    for budget in [128,512,2048]:
        def context(exe):
            r = run([exe,"decompile",paths[binary],"runtime_branches_validation",entry,budget,flag,profile])
            return r
        old, new = context(a.baseline), context(a.candidate)
        assert new.returncode == (2 if kind == "resolver" else 0), (profile.name,new.stderr)
        plain,raw = raw_texts[binary,entry,budget]
        pcs = re.findall(r"^0x([0-9a-f]+)\s+\[",new.stdout,re.M)
        assert pcs == re.findall(r"^0x([0-9a-f]+)\s+\[",raw,re.M)
        work = int(re.search(r"^Instruction work: (\d+)",new.stdout,re.M)[1])
        assert work == plain["work"] <= budget
        assert "Runtime " in new.stdout
        assert old.returncode == (0 if kind == "throw" else 1)
        expected = {"throw":'tailcall_runtime_jni("ThrowNew"', "buffer":'tailcall_runtime_jni("NewDirectByteBuffer"',
                    "callback":"tailcall_runtime(", "resolver":"runtime_branch_fault(target=0x0"}[kind]
        assert expected in new.stdout
        runtime.append({"profile":profile.name,"profile_sha256":sha(profile),"binary":binary,"entry":entry,"budget":budget,
            "without_context":plain,"same_context_before_exit":old.returncode,
            "same_context_before_decoded":len(re.findall(r"^0x([0-9a-f]+)\s+\[",old.stdout,re.M)) if old.returncode != 1 else None,
            "before_error":old.stderr.strip()[:250] if old.returncode == 1 else None,
            "after_decoded":len(pcs),"after_work":work,"after_exit":new.returncode,"same_addresses_as_static":True,
            "observed_target":v.get("observed_target",v.get("x3")),"pid":v["pid"]})
assert len(runtime)==48
# Partial budgets cannot be made complete by a runtime observation.
partial=[]
for kind,binary,entry,flag,budgets in [
    ("throw","counter","0xd80","--jni-runtime",[1,9,18]),
    ("buffer","libimage_processing_util_jni.so","0x719c","--jni-runtime",[1,8,16]),
    ("callback","counter","0xd50","--branch-runtime",[1,2,4]),
    ("resolver","counter","0x10c0","--branch-runtime",[1,2,4])]:
    for mode in ["default","checkjni"]:
        profile=root/f"{mode}-1-{kind}.json"
        for budget in budgets:
            r=run([a.candidate,"decompile",paths[binary],"partial_context",entry,budget,flag,profile])
            assert r.returncode==2,(profile.name,budget,r.stderr)
            work=int(re.search(r"^Instruction work: (\d+)",r.stdout,re.M)[1])
            assert work<=budget
            partial.append({"profile":profile.name,"budget":budget,"work":work,"exit":2})

assert digests == {name: sha(path) for name, path in paths.items()}
result = {"baseline_commit": "fbfb6e36e64db1d1d77cb32ca343d655112c0938", "baseline_sha256": sha(a.baseline),
          "candidate_sha256": sha(a.candidate), "inputs_sha256": digests, "entries": entries,
          "columns": prior["columns"], "comparisons": comparisons, "summaries": summaries,
          "runtime_comparisons": runtime, "partial_context_checks": partial, "jni_context_regressions": jni,
          "scope": "Same 172-entry corpus as validation/wide, at 128/512/2048 work budgets. Original ELF functions executed in controlled ARM64 Android app_process; Hopper statically analyzed. Fresh 16 profiles from four ART processes; old ART captures also replayed. New callback is controlled registered input, null PLT remains INCOMPLETE."}
print(json.dumps(result, separators=(",", ":")))
