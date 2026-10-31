"""Native ARM64 versus decoded IR. No input commercial binaries are executed."""
import argparse
import ctypes as C
import json
from pathlib import Path
import re
import subprocess
p=argparse.ArgumentParser()
p.add_argument("--native",required=True,type=Path)
p.add_argument("--reference",required=True,type=Path)
a=p.parse_args()
root=Path(__file__).resolve().parent
def run(cmd,**kw):return subprocess.run([str(v) for v in cmd],text=True,capture_output=True,timeout=120,**kw)
symbols=run(["nm","-n",a.native]);assert symbols.returncode==0
symbols={n:int(pc,16) for pc,n in re.findall(r"^([0-9a-fA-F]+) T (\S+)$",symbols.stdout,re.M)}
assembly=run(["/usr/bin/objdump","-d",a.native]);assert assembly.returncode==0
words={int(pc,16):int(w,16) for pc,w in re.findall(r"^\s*([0-9a-f]+):\s+([0-9a-f]{8})\s",assembly.stdout,re.M)}
lib=C.CDLL(str(a.native.resolve()))
cases=json.loads((root/"native_cases.json").read_text())
requests=[];wanted=[];labels=[];counts={}
mask=(1<<64)-1
seed=[0x0123456789abcdef,0xfedcba9876543210,0x1122334455667788,0x8877665544332211]
pairs=[(0,0),(mask,1),(1<<63,1<<31),(0x1234567887654321,0xdeadbeefffffffff)]
for case in cases:
    name=case["name"];category=case["category"]
    fn=getattr(lib,name);fn.restype=C.c_uint64
    fn.argtypes=[C.c_uint64]* (4 if category=="memory" else 5)
    flags_set=[0,15] if category in ["extended","memory"] else range(16)
    for flags in flags_set:
        for x,y in pairs:
            registers=[0]*32
            output=(C.c_uint64*3)()
            if category=="memory":
                mem=(C.c_ubyte*256)(*[(n*29+0x83)%256 for n in range(256)])
                base=C.addressof(mem);before=list(mem)
                pointer=base+80
                data=(C.c_uint64*4)(*[(v^x)&mask for v in seed])
                initial=list(data)
                result=fn(pointer,C.addressof(data),flags<<28,C.addressof(output))
                registers[0]=pointer;registers[31]=pointer if case["baseSP"] else 0x777788889999aaa0
                checks={"regs":{0:result,31:output[1] if case["baseSP"] else registers[31]},
                        "flags":output[0]>>28,"bytes":list(mem),
                        "vectors":{case["reg"]:list(data)[:2],1:list(data)[2:]},
                        "reads":(2 if case["pair"] else 1) if case["load"] else 0,
                        "writes":0 if case["load"] else (2 if case["pair"] else 1)}
                request={"regs":registers,"memory_base":base,"bytes":before,"vectors":{"0":initial[:2],"1":initial[2:],"31":initial[:2]}}
            else:
                z=(x^y^0x8123456789abcdef)&mask
                result=fn(x,y,flags<<28,C.addressof(output),z)
                registers[0]=x;registers[1]=y;registers[4]=z;registers[31]=output[2]
                checks={"regs":{0:result,31:output[1]},"flags":output[0]>>28,"reads":0,"writes":0}
                request={"regs":registers}
            request.update(word=words[symbols["_"+name+"_op"]],flags=flags)
            requests.append(request);wanted.append(checks);labels.append(name)
            counts[category]=counts.get(category,0)+1
result=run([a.reference],input=json.dumps(requests))
assert result.returncode==0,result.stderr[:2000]
observed=json.loads(result.stdout)
assert len(observed)==len(wanted)
for n,(actual,expected) in enumerate(zip(observed,wanted)):
    for field,value in expected.items():
        if isinstance(value,dict):
            for index,v in value.items():
                assert actual[field][index]==v,(n,labels[n],hex(requests[n]["word"]),field,index,actual[field][index],v)
        else:
            assert actual[field]==value,(n,labels[n],hex(requests[n]["word"]),field,actual[field],value)
print(json.dumps({"fixtures":len(cases),"native_differential_cases":len(observed),"counts":counts,
                  "checks":"Result GPR/SP, SIMD bits and upper clear, NZCV, full memory and transfer count; CPU oracle uses exactly the assembled target instruction."},indent=2))
