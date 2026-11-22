"""Compare preserved 1d6dcf3 and candidate with identical ELF/entry/budget/capture.
Also checks all prior 29 entry points without context and rejects invalid evidence.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

p=argparse.ArgumentParser()
for name in ["baseline","candidate","elf","hopper"]:
    p.add_argument("--"+name,required=True,type=Path)
a=p.parse_args()
root=Path(__file__).resolve().parent
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def run(command):
    return subprocess.run([str(x) for x in command],text=True,capture_output=True,timeout=90)
def analyze(exe,binary,entry,budget,profile=None):
    cmd=[exe,"decompile",binary,"jni_runtime_comparison",entry,budget]
    if profile is not None: cmd += ["--jni-runtime",profile]
    result=run(cmd)
    addresses=re.findall(r"^0x([0-9a-f]+)\s+\[[^\]]+\]\s+(?:[0-9a-f]{2}\s+){4}(\S+)",result.stdout,re.M)
    assert result.returncode in [0,2] and addresses,result.stderr
    work=re.search(r"^Instruction work: (\d+)",result.stdout,re.M)
    summary={"exit":result.returncode,"decoded":len(addresses),"work":int(work[1]),
             "addresses":[hex(int(pc,16)) for pc,_ in addresses],
             "unsupported":[hex(int(pc,16)) for pc,mnemonic in addresses if mnemonic=="inst.arm64"],
             "indirect_registers":re.findall(r"goto \*(\w+);",result.stdout),
             "runtime_calls":re.findall(r'^\s+call_runtime_jni\("([^"]+)"',result.stdout,re.M),
             "runtime_tail_calls":re.findall(r'^\s+tailcall_runtime_jni\("([^"]+)"',result.stdout,re.M)}
    assert summary["decoded"]<=summary["work"]<=budget
    return summary,result.stdout

assert sha(a.baseline)=="094dcdf9d43a2b2395fc5c9e9bd4683ec999c4e7b39ce8f74b193b35151af9df"
assert sha(a.elf)=="d3e48717c9aa147e0ab21063ba0e8e0211cabf8bf40b222640829519edbf58e1"
assert sha(a.hopper)=="dad6f886261fad0d4cdd01aee6fcf57439c60d7b5c54e62fc97f0180116690e0"
profiles=sorted(root.glob("default-*.json"))+sorted(root.glob("checkjni-*.json"))
assert len(profiles)==4
captures={}
runtime=[]
prefix=[]
for profile in profiles:
    evidence=json.loads(profile.read_text())
    captures[profile.stem]={"pid":evidence["pid"],"table":evidence["table"],"x3":evidence["x3"],
                            "art_sha256":evidence["runtime_sha256"],"calls":evidence["calls"],
                            "thrownew_module":evidence["slots"][1]["module"]}
    assert sha(root/evidence["runtime_image"])==evidence["runtime_sha256"]
    for budget in [128,512,2048]:
        before,_=analyze(a.baseline,a.elf,"0xd80",budget,profile)
        after,text=analyze(a.candidate,a.elf,"0xd80",budget,profile)
        assert (before["exit"],before["decoded"],before["work"],before["indirect_registers"])==(2,23,23,["x3"])
        assert (after["exit"],after["decoded"],after["work"])==(0,23,23)
        assert before["addresses"]==after["addresses"]
        assert before["runtime_calls"]==[] and before["runtime_tail_calls"]==[]
        assert after["runtime_calls"]==["FindClass"] and after["runtime_tail_calls"]==["ThrowNew"]
        assert "offline snapshot" in text and "stable JNIEnv table assumed" in text
        assert evidence["x3"] in text and evidence["table"] in text
        assert "pending exception possible; native return allowed" in text
        assert "call_noreturn" not in text and not after["indirect_registers"]
        runtime.append({"profile":profile.name,"budget":budget,"before":before,"after":after})
    for budget in [1,9,10,18]:
        after,_=analyze(a.candidate,a.elf,"0xd80",budget,profile)
        assert after["exit"]==2 and not after["runtime_tail_calls"]
        prefix.append({"profile":profile.name,"budget":budget,"after":after})
assert len({c["x3"] for c in captures.values()})==4
assert len({c["table"] for c in captures.values()})==4
assert {c["thrownew_module"]["offset"] for k,c in captures.items() if k.startswith("default")} != {c["thrownew_module"]["offset"] for k,c in captures.items() if k.startswith("checkjni")}

prior=json.loads((root.parent/"remaining_paths/verification.json").read_text())
controls=[]
for row in prior["comparisons"]:
    binary=a.hopper if row["binary"]=="hopper" else a.elf
    before,_=analyze(a.baseline,binary,row["entry"],row["budget"])
    after,_=analyze(a.candidate,binary,row["entry"],row["budget"])
    assert before==after,(row["entry"],row["budget"])
    controls.append({"binary":row["binary"],"entry":row["entry"],"budget":row["budget"],
                     "decoded":after["decoded"],"work":after["work"],"exit":after["exit"]})
assert len(controls)==87

negative=[]
original=json.loads(profiles[0].read_text())
for name in ["wrong-elf","wrong-art","wrong-x3","wrong-code","nonexecutable","traversal","missing-art","malformed"]:
    evidence=copy.deepcopy(original)
    evidence["runtime_image"]="libart.so"
    if name=="wrong-elf": evidence["binary_sha256"]="0"*64
    if name=="wrong-art": evidence["runtime_sha256"]="0"*64
    if name=="wrong-x3": evidence["x3"]=evidence["slots"][0]["value"]
    if name=="wrong-code": evidence["slots"][1]["code16"]="00"*16
    if name=="nonexecutable":
        evidence["maps"]=[line.replace("r-xp","r--p") for line in evidence["maps"]]
    if name=="traversal": evidence["runtime_image"]="../libart.so"
    if name=="missing-art": evidence["runtime_image"]="missing.so"
    with tempfile.NamedTemporaryFile("w",suffix=".json",dir=root/"build") as f:
        f.write("{" if name=="malformed" else json.dumps(evidence));f.flush()
        result=run([a.candidate,"decompile",a.elf,"jni","0xd80",2048,"--jni-runtime",f.name])
        assert result.returncode==1 and "Error:" in result.stderr,(name,result.stderr)
        negative.append({"case":name,"exit":1})
for extra in [["--jni-runtime"],["--unknown","value"],["--jni-runtime",profiles[0],"ignored"]]:
    result=run([a.candidate,"decompile",a.elf,"jni","0xd80",128,*extra])
    assert result.returncode==1 and "Usage:" in result.stderr
    negative.append({"case":"invalid-option-"+str(len(negative)),"exit":1})
wrong_entry=run([a.candidate,"decompile",a.elf,"jni","0xddc",128,"--jni-runtime",profiles[0]])
assert wrong_entry.returncode==1 and "entry does not match" in wrong_entry.stderr
negative.append({"case":"wrong-entry","exit":1})
result={"baseline_commit":"1d6dcf383f23406ff33934ab3944b7d41bee5053",
        "sha256":{"baseline":sha(a.baseline),"candidate":sha(a.candidate),"elf":sha(a.elf),"hopper":sha(a.hopper)},
        "runtime_pairs":runtime,"budget_prefix_checks":prefix,"no_context_controls":controls,
        "invalid_context_checks":negative,"captures":captures,
        "comparison_note":"Baseline accepts and silently ignores the trailing runtime option; candidate validates and applies it. Primary file, entry, budget and supplied capture are identical.",
        "scope":"Real ARM64 Android ART app_process loading the original ELF; not the original MetaTrader app process, not a physical device. Offline capture, not live attestation or external ART-body decompilation."}
print(json.dumps(result,indent=2))
