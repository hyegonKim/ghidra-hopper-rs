"""Real ARM64 CPU versus lifted IR; batches bound the validation model's memory."""
import argparse
import ctypes as C
import itertools
import json
from pathlib import Path
import platform
import random
import re
import subprocess

p=argparse.ArgumentParser()
p.add_argument("--native",type=Path,required=True)
p.add_argument("--reference",type=Path,required=True)
a=p.parse_args()
assert platform.machine()=="arm64"
root=Path(__file__).resolve().parent
def run(command,**kw):
    return subprocess.run([str(x) for x in command],capture_output=True,text=True,timeout=120,**kw)
r=run(["nm","-n",a.native]);assert r.returncode==0
symbols={name:int(pc,16) for pc,name in re.findall(r"^([0-9a-fA-F]+) T (\S+)$",r.stdout,re.M)}
r=run(["/usr/bin/objdump","-d",a.native]);assert r.returncode==0
words={int(pc,16):int(w,16) for pc,w in re.findall(r"^\s*([0-9a-f]+):\s+([0-9a-f]{8})\s",r.stdout,re.M)}
cases=json.loads((root/"native_cases.json").read_text())
lib=C.CDLL(str(a.native.resolve()))
mask=(1<<64)-1
pairs=[(0,0),(mask,1),(0x7fffffff,mask),(0x80000000,1),(1<<63,1),(0x7fffffffffffffff,1),(0x8123456789abcdef,0xfedcba9876543210)]
edges=[0,1,2,mask,1<<63,(1<<63)-1,0xffffffff00000000,0x80000000,0x8123456789abcdef]
rng=random.Random(0x43434d50)
random_pairs=[(rng.getrandbits(64),rng.getrandbits(64)) for _ in range(128)]
indices={2:[0,1,3,0xdeadbeef00000002,0xffffffff00000001],
         3:[0,1,3,mask,mask-1],
         6:[0,1,0xffffffff,0xfffffffe,0xaabbccdd00000003],
         7:[0,1,3,mask,mask-1]}
requests=[];expected=[];labels=[]
counts={};checked=0;batches=0;chain_paths=set()
def flush():
    global checked,batches
    if not requests:return
    r=run([a.reference],input=json.dumps(requests))
    assert r.returncode==0,r.stderr[:2000]
    output=json.loads(r.stdout);assert len(output)==len(expected)
    for actual,wanted,label in zip(output,expected,labels):
        for field,value in wanted.items():
            if isinstance(value,dict):
                for index,v in value.items():assert actual[field][index]==v,(checked,label,field,index,actual[field][index],v)
            else:assert actual[field]==value,(checked,label,field,actual[field],value)
        checked+=1
    batches+=1;requests.clear();expected.clear();labels.clear()
def add(case,row,wanted):
    start=symbols["_"+case["name"]+"_op"]
    if case["kind"]=="chain":
        row["words"]=[words[pc] for pc in range(start,symbols["_"+case["name"]+"_end"],4)]+[0xd65f03c0]
    else:row["word"]=words[start]
    requests.append(row);expected.append(wanted);labels.append(case["name"])
    counts[case["kind"]]=counts.get(case["kind"],0)+1
    if len(requests)>=4096:flush()
for case in cases:
    name=case["name"];kind=case["kind"]
    fn=getattr(lib,name);fn.restype=C.c_uint64
    fn.argtypes=[C.c_uint64]*(5 if kind=="memory" else 4)
    if kind=="memory":
        for flags in [0,15]:
            for index in indices[case["option"]]:
                mem=(C.c_ubyte*512)(*[(n*29+0x83)%256 for n in range(512)])
                base=C.addressof(mem);before=list(mem)
                pointer=(base+143)&~15
                data=(C.c_uint64*4)(0x0123456789abcdef,0xfedcba9876543210,0,0)
                seed=list(data)[:2]
                out=(C.c_uint64*2)()
                result=fn(pointer,index,flags<<28,C.addressof(out),C.addressof(data))
                regs=[0]*32;regs[0]=pointer;regs[1]=index;regs[31]=pointer if case["rn"]==31 else out[1]
                row={"regs":regs,"flags":flags,"memory_base":base,"bytes":before,"vectors":{"0":seed,"31":seed}}
                wanted={"regs":{0:result,1:index,31:regs[31]},"flags":out[0]>>28,
                        "vectors":{0:list(data)[:2],31:list(data)[2:]},"bytes":list(mem),
                        "reads":int(case["load"]),"writes":int(not case["load"])}
                add(case,row,wanted)
    else:
        samples=[(x,y,flags) for flags in range(16) for x,y in (itertools.product(edges,repeat=2) if kind=="smulh" else pairs)]
        if kind=="smulh":samples += [(x,y,flags) for flags in [0,15] for x,y in random_pairs]
        for x,y,flags in samples:
            out=(C.c_uint64*2)()
            result=fn(x,y,flags<<28,C.addressof(out))
            regs=[0]*32;regs[0]=x;regs[1]=y;regs[31]=0xfedcba9876543210
            add(case,{"regs":regs,"flags":flags},
                {"regs":{0:result,1:out[1],31:regs[31]},"flags":out[0]>>28,"reads":0,"writes":0})
            if kind=="chain":chain_paths.add(result)
flush()
assert chain_paths=={0x11,0x22}
print(json.dumps({"fixtures":len(cases),"native_cases":checked,"batches":batches,"counts":counts,
                  "condition_codes":16,"incoming_nzcv_patterns":16,"fallback_nzcv_patterns":16,
                  "chain_branch_results":sorted(chain_paths),
                  "checks":"GPR/SP, incoming/fallback NZCV, signed multiply high, both V0/V31 including scalar upper clearing, full memory, one transfer and no writeback."},indent=2))
