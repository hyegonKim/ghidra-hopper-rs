# SMADDL/SMULL·MOVI 구현과 동일 조건 비교

검증일: 2026-10-31. 기준 커밋은 `ae18898766bc24b97e839afb26fc9bdac23f79b8`이다. 직전 [CCMP/SMULH 검증](../conditional_compare/REPORT.md)의 입력 파일 7개와 172개 진입점을 그대로 사용했다. 양쪽에 각각 128/512/2,048의 명령 작업 예산을 적용한 516쌍에서 이전 결과의 명령 수·작업량·종료 코드·미지원 주소/워드·간접 레지스터·ObjC 호출 수를 재현했다. 모든 입력 SHA-256을 실행 전후 대조했다.

## 실제 의미 구현

- **SMADDL**: Rn/Rm의 하위 32비트를 signed 값으로 읽어 64비트 곱을 구한 뒤 64비트 Ra에 더한다. 결과는 modulo 2^64다. 입력 X 레지스터의 상위 32비트는 곱에 영향을 주지 않는다. 입력과 목적지가 겹쳐도 쓰기 전에 모든 입력을 읽는다.
- **SMULL**: Ra가 31인 SMADDL의 별칭으로, 64비트 0을 addend로 사용한다. Rn/Rm/Ra 31은 ZR이고 Rd 31은 버리는 쓰기다. SP와 혼동하지 않으며 NZCV를 보존한다. SMSUBL·UMADDL 등 다른 명령을 이 구현으로 인정하지 않는다.
- **MOVI**: 남은 8B/16B, 4H/8H, 2S/4S 형식을 구현했다. LSL #0/#8/#16/#24와 MSL #8/#16은 인코딩이 허용하는 요소 크기에만 적용한다. MSL은 아래쪽 비트를 1로 채운다. 요소를 반복해 64/128비트를 만들고 Q=0의 상위 64비트를 0으로 만든다. 기존 D/2D byte-mask 형식도 유지한다.
- MOVI의 op/cmode 및 고정 비트를 검사해 ORR/BIC immediate, MVNI, FMOV와 예약 형식이 VectorImmediate로 오인되지 않게 했다. V31은 SIMD 데이터 레지스터이며 GPR/ZR/SP와 별개다.
- 새 `SignedMultiplyAddLong` Pcode에 GPR 목적지를 명시했다. 해당 쓰기는 오래된 문자열/인자 provenance를 무효화하고 MOVI는 GPR provenance를 보존한다. public enum을 exhaustive match하는 외부 Rust 코드는 새 variant 처리가 필요하다.

설계의 ISA 근거는 [Arm A64 2025-03 명세](https://documentation-service.arm.com/static/67e40f3398aa3c3b6eea6a85)의 SMADDL 및 MOVI 설명이다. SMADDL 인코딩은 [LLVM AArch64 assembler 테스트](https://github.com/llvm/llvm-project/blob/main/llvm/test/MC/AArch64/basic-a64-instructions.s)와도 대조했다. 명령 실행 의미의 독립 기준은 아래 실제 CPU 결과다.

## 원본 바이너리 분석 비교

| 양쪽 명령 작업 예산 | 진입점 수 | 지원 범위 내 종료, 이전→수정 | 출력 명령 수 합, 이전→수정 |
| --- | ---: | ---: | ---: |
| 128 | 172 | 146→146 | 5,067→5,067 |
| 512 | 172 | 162→163 | 7,676→7,707 |
| 2,048 | 172 | 166→168 | 8,645→8,737 |

같은 파일·진입점·예산에서 명령 수가 줄거나 지원 범위 내 종료가 실패로 바뀐 비교는 없다. 128개 예산에서는 새 명령에 도달하기 전의 작업 상한 때문에 차이가 없다.

| ELF / 진입점 / 함수 | 예산 | 출력 명령 수 | 종료 코드 |
| --- | ---: | ---: | ---: |
| libimage_processing_util_jni.so / `0x6a3c` / nativeRotateYUV | 2,048 | 541→602 | 2→0 |
| libchannels.so / `0x87aa8` / getAvatar | 512 | 194→225 | 2→0 |
| libchannels.so / `0x87aa8` / getAvatar | 2,048 | 194→225 | 2→0 |

nativeRotateYUV의 이전 중단점은 SMADDL `0x2944`, `0x2a68`, `0x6ea8`, `0x6fe4`, `0x7100` 및 SMULL `0x6ed4`, `0x7010`, `0x712c`였다. getAvatar의 이전 중단점은 `0x80680: 0x0f000600`, 즉 `MOVI V0.2S, #0x10`이었다. 수정 후 두 CFG에 미지원 명령이나 미해결 간접 분기는 없다.

Hopper 98개 진입점의 결과는 세 예산 모두 같다. 2,048개 예산에서 98→98개 지원 범위 내 종료, 출력 명령 합 3,769→3,769이며 주요 진입점 `0x100002ddc`는 출력 1,121개·작업량 1,945를 유지한다. 최종 release metadata probe에서도 selector 51개·검증된 ObjC stub 50개를 유지했다. counter 31개 진입점 역시 전부 이전과 같다.

출력 명령 합에는 진입점 간 중복 CFG가 포함된다. 실제 프로세스 실행 명령 수나 전체 코드의 커버리지 비율을 뜻하지 않는다. 지원 범위 내 종료는 선택 진입점의 정적 CFG에서 예산/미지원/미해결 분기로 중단되지 않았다는 뜻이며, 외부 호출은 opaque call로 남는다. 원본 상용 앱과 Android 프로세스 전체를 이번에 실행한 것은 아니다.

## 실제 ARM64 CPU 대조

ARM64 Mac에서 [native.s](native.s)를 dylib로 빌드하여 실제 명령을 실행했다. SMADDL/SMULL과 새 MOVI lane 형식은 어셈블러 mnemonic으로 작성해 Rust의 비트마스크 생성과 독립적으로 인코딩했다. 기존 D/2D MOVI 회귀는 모든 byte-mask의 인코딩을 실행했다. [verify_native.py](verify_native.py)는 실제 기계어 워드를 읽어 같은 Pcode를 실행하고 결과를 대조한다.

**최종 release reference에서 111,680건 전부 통과**했다. 총 10,253개 fixture를 28개 batch로 검사했다.

| 검증 종류 | 실제 실행 사례 |
| --- | ---: |
| SMADDL/SMULL, 입력·목적지 겹침 및 ZR 등 13형식 | 70,720 |
| MOVI 모든 정수 op/cmode/Q/imm8, V0/V31, 두 nonzero 초기 벡터·두 NZCV | 40,960 |

SMADDL은 음수·INT32_MIN/MAX·상위 32비트가 다른 입력·64비트 overflow addend·난수 및 입력 NZCV 16종을 포함한다. 목적지가 lhs/rhs/addend와 겹치는 경우, 세 입력이 같은 경우, SMULL·ZR 입력·버리는 목적지를 확인했다. CPU의 X0/X1/X2 결과와 변경되지 않아야 하는 GPR/SP/NZCV를 비교했다.

MOVI는 정수 인코딩 10,240종(모든 imm8·20개 op/cmode/Q 조합·V0/V31)을 검사했다. SIMD 두 레지스터의 전체 128비트를 비교하므로 Q=0 상위 비트 초기화와 다른 벡터 보존도 확인한다. 대상 명령에 메모리 접근이 없는지도 검사했다. wrapper의 입출력용 메모리 접근은 대상 명령의 접근 횟수에 포함하지 않는다.

추가 검증은 디버그 전체 **146개**, 관련 릴리스 **23개** 테스트 통과다. 예약/인접 명령의 거부, 모든 MOVI 정수 요소 상수, stale 문자열 추론, 작업 예산 1/2/3을 검사했다. `cargo clippy --all-targets -- -D warnings`, `cargo fmt --check`, `git diff --check`도 통과했다.

기존 ART 캡처 네 개의 JNI 회귀 12쌍은 각각 출력 23개·종료 코드 0 및 ThrowNew tailcall을 유지한다. 기존 캡처와 ART 이미지를 다시 검증해 사용했으며 이번에 새 Android 런타임 관찰을 수집한 것은 아니다.

## 남은 중단 원인

2,048개 예산의 172개 선택 진입점에서 남은 미지원 명령 워드는 없다. 다음 네 진입점은 런타임 간접 대상으로 인해 `INCOMPLETE`를 유지한다. 이 결과가 다른 함수나 모든 ARM64 명령의 지원을 뜻하지는 않는다.

| 입력 / 진입점 | 미해결 대상 |
| --- | --- |
| counter / `0xd80` | JNI `BR x3`; 기존 검증된 ART 캡처를 제공하면 출력 23개·지원 범위 내 종료 |
| counter / `0xd50` | 런타임 간접 `x16` |
| counter / `0x10c0` | PLT resolver의 런타임 간접 `x17` |
| image_processing / `0x719c` | nativeNewDirectByteBuffer의 간접 `x3` |

추측한 간접 대상을 삽입하지 않았다. 모든 비교의 원래/새 명령 수·비용·상태·중단점은 [verification.json](verification.json)에 보존했다. 이전 보고서와 원시 검증 결과는 덮어쓰지 않았다.

## 빌드 식별 및 재현

기준 실행 파일 SHA-256: `fadd1b3e30cb033d177fc39f9f748d3874e452dda11cfc8b5bb66938dcc340e5`.

수정 release·설치본 SHA-256: `493cc79368e6fad68156ecaaa0af0b2eb8e3b71100be31504ce9cadd02f97f8e`.

기준 보존본: `/Users/gimhyegon/Desktop/REA_Analysis/outputs/ghidra-hopper-rs-long-movi-20261031/ghidra-hopper-rs.before-long-movi`.

입력 경로와 SHA-256은 [기존 입력 식별 표](../wide/REPORT.md#빌드-및-입력-식별) 및 verification.json과 같다. 설치본 `/Users/gimhyegon/.local/bin/ghidra-hopper-rs`를 최종 release로 갱신하고 Hopper 주요 진입점과 변경된 Android 두 진입점의 출력·작업량·종료 상태를 재확인했다. 상용 입력 바이너리·pulled ART·생성 dylib는 커밋하지 않는다.

ARM64 Mac, Rust, Python 3, Xcode clang/objdump/nm이 필요하다. ART 캡처 회귀에는 [기존 환경](../jni_runtime/REPORT.md)의 해당 libart.so 이미지도 필요하다.

```sh
cargo test
cargo clippy --all-targets -- -D warnings
cargo fmt --check
cargo build --release
cargo build --release --example remaining_reference --example metadata_probe
cargo test --release --test long_movi --test wide --test remaining_paths --test conditional_compare
mkdir -p validation/long_movi/build
clang -arch arm64 -dynamiclib validation/long_movi/native.s \
  -o validation/long_movi/build/native.dylib
python3 validation/long_movi/verify.py \
  --baseline /path/to/ghidra-hopper-rs.before-long-movi \
  --candidate target/release/ghidra-hopper-rs \
  --hopper "/Applications/Hopper Disassembler.app/Contents/MacOS/hopper" \
  --elf-dir /path/to/mt5/lib/arm64-v8a \
  --native validation/long_movi/build/native.dylib \
  --reference target/release/examples/remaining_reference
```

verify.py의 JSON 표준 출력을 저장한 것이 verification.json이다. 이 스크립트는 바로 이전 후보와 기준 보존본의 해시·진입점별 결과를 먼저 대조하므로 다른 버전을 기준으로 잘못 비교하면 실패한다.
