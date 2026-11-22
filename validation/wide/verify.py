"""Same-input/same-entry/same-budget broad survey; generated binaries stay in build/.
Result rows are compact arrays; the columns field defines their schema.
"""
import argparse
import ctypes as C
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import sys

p=argparse.ArgumentParser()
for name in ["baseline","candidate","hopper","elf-dir","metadata","native","reference","objc"]:
    p.add_argument("--"+name,required=True,type=Path)
a=p.parse_args()
root=Path(__file__).resolve().parent
def run(command,**kw):
    return subprocess.run([str(x) for x in command],text=True,capture_output=True,timeout=120,**kw)
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def macho(path):
    b=path.read_bytes()
    if b[:4]==bytes.fromhex("cafebabe"):
        count=struct.unpack_from(">I",b,4)[0]
        item=next(struct.unpack_from(">IIIII",b,8+n*20) for n in range(count) if struct.unpack_from(">I",b,8+n*20)[0]==0x100000c)
        b=b[item[2]:item[2]+item[3]]
    segments=[];sections=[];at=32
    for _ in range(struct.unpack_from("<I",b,16)[0]):
        cmd,size=struct.unpack_from("<II",b,at)
        if cmd==0x19:
            va,vs,fo,fs=struct.unpack_from("<4Q",b,at+24)
            segments.append((va,fo,fs))
            for n in range(struct.unpack_from("<I",b,at+64)[0]):
                q=at+72+n*80
                name=b[q:q+16].split(b"\0")[0].decode()
                addr,length=struct.unpack_from("<QQ",b,q+32)
                file,flags,first,stride=struct.unpack_from("<I12xIII",b,q+48)
                sections.append((name,addr,length,file,flags,stride))
        at+=size
    return b,segments,sections
def elf(path):
    b=path.read_bytes()
    shoff=struct.unpack_from("<Q",b,40)[0]
    stride,count,strings=struct.unpack_from("<HHH",b,58)
    sections=[struct.unpack_from("<IIQQQQIIQQ",b,shoff+n*stride) for n in range(count)]
    s=sections[strings];names=b[s[4]:s[4]+s[5]]
    exports=[]
    for s in sections:
        if s[1]!=11:continue
        strings=sections[s[6]];dyn=b[strings[4]:strings[4]+strings[5]]
        for n in range(s[5]//s[9]):
            name,info,_,defined,pc,_=struct.unpack_from("<IBBHQQ",b,s[4]+n*s[9])
            if defined and pc and info&15==2:
                text=dyn[name:].split(b"\0")[0].decode()
                if text.startswith(("Java_","JNI_On")):exports.append((pc,text))
    return sorted(set(exports)),[(names[s[0]:].split(b"\0")[0].decode(),s[3],s[5]) for s in sections]
paths={"hopper":a.hopper,"counter":a.elf_dir/"libdatastore_shared_counter.so"}
for name in ["libsurface_util_jni.so","libimage_processing_util_jni.so","libbarhopper_v3.so","libchannels.so","libcommon.so"]:
    paths[name]=a.elf_dir/name
digests={key:sha(path) for key,path in paths.items()}
assert sha(a.baseline)=="f60930bb9ffadf2de9259bb44ebf8e92141a308e7e857e41c52d5a43cb651606"
assert digests["hopper"]=="dad6f886261fad0d4cdd01aee6fcf57439c60d7b5c54e62fc97f0180116690e0"
assert digests["counter"]=="d3e48717c9aa147e0ab21063ba0e8e0211cabf8bf40b222640829519edbf58e1"
entries=[];seen=set()
def add(binary,pc,name,kind):
    if (binary,pc) not in seen:
        entries.append({"binary":binary,"entry":hex(pc),"name":name,"kind":kind});seen.add((binary,pc))
prior=json.loads((root.parent/"remaining_paths/verification.json").read_text())
for row in prior["comparisons"]:
    add("hopper" if row["binary"]=="hopper" else "counter",int(row["entry"],16),row["name"],"prior")
_,_,hsections=macho(a.hopper)
for name,pc,length,_,flags,stride in hsections:
    if name=="__objc_stubs":
        for n in range(length//32):add("hopper",pc+n*32,f"objc stub {n}","objc-stub")
    elif flags&255==8 and stride==12:
        for n in range(length//stride):add("hopper",pc+n*stride,f"import stub {n}","import-stub")
for pc in [0xd40,0xd48,0xd50,0xd64]:add("counter",pc,"unexported init/fini helper","helper")
_,counter_sections=elf(paths["counter"])
for name,pc,length in counter_sections:
    if name==".plt":
        add("counter",pc,"dynamic resolver header","plt-resolver")
        for n in range(32,length,16):add("counter",pc+n,f"PLT {n//16-2}","plt-stub")
selection={}
for key in paths:
    if key in ["hopper","counter"]:continue
    exports,_=elf(paths[key]);selection[key]={"jni_exports":len(exports),"sampling":"all up to 12; otherwise 12 address-uniform entries plus every JNI_OnLoad/OnUnload"}
    selected=exports if len(exports)<=12 else [exports[n*(len(exports)-1)//11] for n in range(12)]
    selected+= [v for v in exports if v[1].startswith("JNI_On")]
    for pc,name in sorted(set(selected)):add(key,pc,name,"jni-export")
def analyze(exe,path,pc,budget,profile=None):
    command=[exe,"decompile",path,"wide_comparison",pc,budget]
    if profile is not None:command+=["--jni-runtime",profile]
    result=run(command)
    rows=re.findall(r"^0x([0-9a-f]+)\s+\[[^\]]+\]\s+((?:[0-9a-f]{2}\s+){4})(\S+)",result.stdout,re.M)
    assert result.returncode in [0,2] and rows,(path,pc,result.returncode,result.stderr[:500])
    work=re.search(r"^Instruction work: (\d+)",result.stdout,re.M)
    out={"decoded":len(rows),"work":int(work[1]),"exit":result.returncode,
         "unsupported":[[hex(int(pc,16)),hex(int.from_bytes(bytes.fromhex(word),"little"))] for pc,word,op in rows if op=="inst.arm64"],
         "indirect":re.findall(r"goto \*(\w+);",result.stdout),
         "objc_named_tail":len(re.findall(r"// verified selector ",result.stdout)),
         "objc_calls":len(re.findall(r"ObjcMessage \{",result.stdout))}
    assert out["decoded"]<=out["work"]<=budget
    return out,result.stdout
comparisons=[];summaries={}
for index,entry in enumerate(entries):
    binary=entry["binary"]
    for budget in [128,512,2048]:
        before,_=analyze(a.baseline,paths[binary],entry["entry"],budget)
        after,text=analyze(a.candidate,paths[binary],entry["entry"],budget)
        if entry["kind"]=="objc-stub":
            assert before["objc_named_tail"]==0 and after["objc_named_tail"]==1
            assert (before["exit"],after["exit"],before["decoded"],after["decoded"])==(0,0,5,5)
        if binary=="counter":
            assert (before["decoded"],before["work"],before["exit"])==(after["decoded"],after["work"],after["exit"])
        if binary=="libimage_processing_util_jni.so" and budget==2048 and entry["entry"] in ["0x60cc","0x61bc","0x68f4","0x7154"]:
            assert after["exit"]==0 and after["decoded"]>before["decoded"]
        comparisons.append([index,budget,before["decoded"],after["decoded"],before["work"],after["work"],before["exit"],after["exit"],
                            before["unsupported"],after["unsupported"],before["indirect"],after["indirect"],before["objc_calls"],after["objc_calls"]])
        group=summaries.setdefault(f"{binary}/{budget}",{"entries":0,"before_supported":0,"after_supported":0,"before_decoded":0,"after_decoded":0})
        group["entries"]+=1;group["before_supported"]+=int(before["exit"]==0);group["after_supported"]+=int(after["exit"]==0)
        group["before_decoded"]+=before["decoded"];group["after_decoded"]+=after["decoded"]

def metadata(path):
    result=run([a.metadata,path]);assert result.returncode==0,result.stderr
    return json.loads(result.stdout)
def compare_dyld(path):
    meta=metadata(path);data,segments,_=macho(path)
    dyld=run(["xcrun","dyld_info","-arch","arm64","-fixups",path]);assert dyld.returncode==0,dyld.stderr
    refs={int(a,16):int(b,16) for a,b in re.findall(r"__objc_selrefs\s+(0x[0-9a-fA-F]+)\s+rebase\s+(0x[0-9a-fA-F]+)",dyld.stdout)}
    assert refs
    def string(address):
        at=next(fo+address-va for va,fo,size in segments if va<=address<va+size)
        return data[at:data.index(b"\0",at)].decode()
    expected={hex(slot):string(target) for slot,target in refs.items()}
    actual={row["address"]:row["selector"] for row in meta["selectors"]}
    assert actual==expected,(path,len(actual),len(expected))
    for stub in meta["stubs"]:
        assert stub["selector"]==expected[stub["selref"]]
        assert int(stub["target"],16)==refs[int(stub["selref"],16)]
    return {"selrefs_matched":len(actual),"stubs_proven":len(meta["stubs"]),"stubs":meta["stubs"]}
hopper_metadata=compare_dyld(a.hopper);assert hopper_metadata["selrefs_matched"]==51 and hopper_metadata["stubs_proven"]==50
old_inspect=run([a.baseline,"inspect",a.hopper]);new_inspect=run([a.candidate,"inspect",a.hopper])
assert json.loads(old_inspect.stdout)["objc_stubs_verified"]==0 and json.loads(new_inspect.stdout)["objc_stubs_verified"]==50
own_metadata=compare_dyld(a.objc);assert own_metadata["stubs_proven"]==1
library=C.CDLL(str(a.objc.resolve()));library.objc_probe.argtypes=[C.c_uint64];library.objc_probe.restype=C.c_uint64
values=[0,1,0x7fffffff,0x80000000,0xffffffff,1<<63,(1<<64)-1,0x8123456789abcdef]
for value in values:assert library.objc_probe(value)==(value*3+7)% (1<<64)
jni=[]
for profile in sorted((root.parent/"jni_runtime").glob("default-*.json"))+sorted((root.parent/"jni_runtime").glob("checkjni-*.json")):
    for budget in [128,512,2048]:
        before,_=analyze(a.baseline,paths["counter"],"0xd80",budget,profile)
        after,text=analyze(a.candidate,paths["counter"],"0xd80",budget,profile)
        assert before==after and after["exit"]==0 and 'tailcall_runtime_jni("ThrowNew"' in text
        jni.append({"profile":profile.name,"budget":budget,"decoded":after["decoded"],"work":after["work"],"exit":0})
assert len(jni)==12
native=run([sys.executable,root/"verify_native.py","--native",a.native,"--reference",a.reference]);assert native.returncode==0,native.stderr[:2000]
assert digests=={key:sha(path) for key,path in paths.items()}
result={"baseline_commit":"eaced05140642ffd9e012f58ea2a8eccd33a20f2","baseline_sha256":sha(a.baseline),
        "candidate_sha256":sha(a.candidate),"inputs_sha256":digests,"selection":selection,"entries":entries,
        "columns":["entry_index","budget","before_decoded","after_decoded","before_work","after_work","before_exit","after_exit",
                   "before_unsupported_address_word","after_unsupported_address_word","before_indirect_registers","after_indirect_registers","before_objc_calls","after_objc_calls"],
        "comparisons":comparisons,"summaries":summaries,"hopper_metadata":hopper_metadata,"own_objc_metadata":own_metadata,
        "native":json.loads(native.stdout),"native_objc_calls":len(values),"jni_context_regressions":jni,
        "scope":"Intra-procedure static CFG of selected entries, opaque calls retained; native ARM64 snippets and own ObjC fixture executed. Original input libraries/apps are not executed in this round."}
print(json.dumps(result,separators=(",",":")))
