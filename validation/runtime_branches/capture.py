"""Controlled ARM64 ART replay; stdout contains fresh profiles, never old captures."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess

p = argparse.ArgumentParser()
for name in ["sdk", "ndk", "java-home", "elf-dir"]:
    p.add_argument("--" + name, type=Path, required=True)
p.add_argument("--device", required=True)
a = p.parse_args()
root = Path(__file__).resolve().parent
build = root / "build"
build.mkdir(exist_ok=True)
adb = a.sdk / "platform-tools/adb"


def run(command):
    r = subprocess.run([str(v) for v in command], text=True, capture_output=True, timeout=120)
    assert r.returncode == 0, (command[0], r.returncode, r.stderr[:2000], r.stdout[:1000])
    return r.stdout


def shell(*command):
    return run([adb, "-s", a.device, "shell", *command])


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


assert shell("getprop", "ro.product.cpu.abi").strip() == "arm64-v8a"
assert shell("getprop", "sys.boot_completed").strip() == "1"
run([a.java_home / "bin/javac", "--release", "8", "-d", build, root / "RuntimeBranchesProbe.java"])
run([a.sdk / "build-tools/35.0.0/d8", "--min-api", "26", "--output", build, build / "RuntimeBranchesProbe.class"])
clang = a.ndk / "toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android26-clang++"
provider = build / "librea_runtime_branches.so"
run([clang, "-std=c++17", "-shared", "-fPIC", "-O2", "-Wall", "-Wextra", "-Werror", "-static-libstdc++", root / "probe.cpp", "-ldl", "-o", provider])
counter = a.elf_dir / "libdatastore_shared_counter.so"
image = a.elf_dir / "libimage_processing_util_jni.so"
remote = f"/data/local/tmp/rea-runtime-four-{os.getpid()}"
shell("mkdir", remote)
profiles = {}
try:
    for path in [provider, build / "classes.dex", counter, image]:
        run([adb, "-s", a.device, "push", path, remote + "/"])
        assert shell("sha256sum", remote + "/" + path.name).split()[0] == sha(path)
    for mode in ["default", "checkjni"]:
        for repeat in [1, 2]:
            key = f"{mode}-{repeat}"
            command = [f"CLASSPATH={remote}/classes.dex", "app_process64"]
            if mode == "checkjni":
                command += ["-Xcheck:jni"]
            command += ["/system/bin", "RuntimeBranchesProbe", remote + "/" + provider.name,
                        remote + "/" + counter.name, remote + "/" + image.name, remote + "/" + key]
            shell(*command)
            for kind in ["throw", "buffer", "callback", "resolver"]:
                name = f"{key}-{kind}"
                path = build / (name + ".json")
                run([adb, "-s", a.device, "pull", remote + "/" + name + ".json", path])
                row = json.loads(path.read_text())
                source = image if kind == "buffer" else counter
                if kind in ["throw", "buffer"]:
                    module = row["slots"][0]["module"]["path"]
                    runtime = build / "libart.so"
                elif kind == "callback":
                    module = row["target"]["module"]["path"]
                    runtime = provider
                else:
                    module = remote + "/" + counter.name
                    runtime = build / counter.name
                run([adb, "-s", a.device, "pull", module, runtime])
                assert shell("sha256sum", module).split()[0] == sha(runtime)
                row.update(binary_sha256=sha(source), runtime_sha256=sha(runtime), runtime_image="build/" + runtime.name,
                           requested_mode=mode, captured_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                           capture_provenance="Controlled app_process with original ELF; supplied offline evidence, not attestation")
                profiles[name] = row
finally:
    shell("rm", "-rf", remote)  # Only the fresh directory created by this invocation.
print(json.dumps(profiles, separators=(",", ":")))
