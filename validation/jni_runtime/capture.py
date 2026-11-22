"""Build/run the real ART probe on one explicitly selected ARM64 Android device.
Outputs capture profiles as JSON on stdout. Original ELF/ART are not redistributed.
The caller saves each profile beside this script; pulled ART lives in build/.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

p = argparse.ArgumentParser()
for name in ["sdk", "ndk", "java-home", "elf"]:
    p.add_argument("--" + name, required=True, type=Path)
p.add_argument("--device", required=True)
p.add_argument("--repeats", type=int, default=2)
a = p.parse_args()
assert 1 <= a.repeats <= 4
root = Path(__file__).resolve().parent
build = root / "build"
build.mkdir(exist_ok=True)
adb = a.sdk / "platform-tools/adb"
clang = a.ndk / "toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android26-clang++"
env = dict(os.environ, JAVA_HOME=str(a.java_home))
def run(command):
    result = subprocess.run([str(x) for x in command], capture_output=True, text=True, timeout=120, env=env)
    if result.returncode:
        raise RuntimeError(f"{command[0]} failed ({result.returncode}): {result.stderr[:1500]} {result.stdout[:1500]}")
    return result.stdout
def shell(*command):
    return run([adb, "-s", a.device, "shell", *command])
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

assert shell("getprop", "ro.product.cpu.abi").strip() == "arm64-v8a"
assert shell("getprop", "sys.boot_completed").strip() == "1"
run([a.java_home / "bin/javac", "--release", "8", "-d", build, root / "JniRuntimeProbe.java"])
run([a.sdk / "build-tools/35.0.0/d8", "--min-api", "26", "--output", build, build / "JniRuntimeProbe.class"])
run([clang, "-std=c++17", "-shared", "-fPIC", "-O2", "-Wall", "-Wextra", "-Werror", "-static-libstdc++",
     root / "probe.cpp", "-ldl", "-o", build / "libjni_runtime_probe.so"])
remote = f"/data/local/tmp/rea-jni-brx3-{os.getpid()}"
shell("mkdir", remote)
profiles = {}
try:
    for path in [build / "libjni_runtime_probe.so", build / "classes.dex", a.elf]:
        run([adb, "-s", a.device, "push", path, remote + "/"])
    remote_elf = remote + "/" + a.elf.name
    assert shell("sha256sum", remote_elf).split()[0] == sha(a.elf)
    for mode in ["default", "checkjni"]:
        for repeat in range(1, a.repeats + 1):
            key = f"{mode}-{repeat}"
            output = remote + "/" + key + ".json"
            command = [f"CLASSPATH={remote}/classes.dex", "app_process64"]
            if mode == "checkjni":
                command.append("-Xcheck:jni")
            command += ["/system/bin", "JniRuntimeProbe", remote + "/libjni_runtime_probe.so", remote_elf, output]
            shell(*command)
            run([adb, "-s", a.device, "pull", output, build / (key + ".json")])
            row = json.loads((build / (key + ".json")).read_text())
            assert row["x3"] == next(s["value"] for s in row["slots"] if s["index"] == 14)
            assert row["calls"]["trap_hits"] == 1 and row["calls"]["message_verified"]
            profiles[key] = row
    paths = {s["module"]["path"] for row in profiles.values() for s in row["slots"]}
    assert len(paths) == 1
    art_path = next(iter(paths))
    run([adb, "-s", a.device, "pull", art_path, build / "libart.so"])
    art_hash = sha(build / "libart.so")
    assert shell("sha256sum", art_path).split()[0] == art_hash
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()
    for key, row in profiles.items():
        row.update(binary_sha256=sha(a.elf), runtime_sha256=art_hash,
                   runtime_image="build/libart.so", captured_at=now, requested_mode=key.split("-")[0],
                   capture_provenance="Local controlled Android ART execution; supplied offline evidence, not attestation")
    offsets = {mode: {next(s["module"]["offset"] for s in row["slots"] if s["index"] == 14)
                      for key, row in profiles.items() if key.startswith(mode + "-")}
               for mode in ["default", "checkjni"]}
    assert len(offsets["default"]) == len(offsets["checkjni"]) == 1
    assert offsets["default"] != offsets["checkjni"], "Expected distinct normal and CheckJNI tables"
finally:
    shell("rm", "-rf", remote)  # Only this invocation's newly created scratch directory.
print(json.dumps(profiles, indent=2))
