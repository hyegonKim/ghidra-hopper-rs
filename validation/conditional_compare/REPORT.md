# CCMP·SMULH·SIMD register-offset 구현 및 동일 조건 검증

검증일: 2026-10-31. 기준 커밋은 `37c847f85fa1bf4bffccf348dab2a16b0d5a552e`이다. 직전 보고서의 172개 진입점·입력 파일을 그대로 사용하고, 양쪽에 각각 128/512/2,048의 명령 작업 예산을 적용했다. 516쌍 모두 이전 실행 결과의 명령 수·작업량·종료 코드·미지원 주소/워드·간접 분기·ObjC 호출 수까지 재현했다. 입력 SHA-256도 실행 전후 대조했다.

## 구현

- **CCMP/CCMN**: 32/64비트, 레지스터/imm5 형식. 조건은 변경 전 NZCV로 판정한다. 참이면 SUB/ADD의 NZCV, 거짓이면 명령에 들어 있는 4비트 fallback NZCV를 쓴다. GPR을 변경하지 않고 Rn/Rm 31은 ZR로 읽는다. immediate 31은 숫자 31이다. AL/NV 조건도 실제 CPU와 대조했다.
- **SMULH**: 부호 있는 64×64비트 곱의 상위 64비트. signed 128비트 곱과 산술 우측 시프트로 구현했으며 피연산자/목적지 별칭, XZR·버리는 목적지와 NZCV 보존을 검증했다. UMULH나 SMADDL을 같은 명령으로 인정하지 않는다.
- **SIMD register-offset LDR/STR B/H/S/D/Q**: UXTW/LSL/SXTW/SXTX 확장 후 0 또는 크기에 따른 스케일을 적용한다. Q의 16바이트 스케일도 지원한다. 원래 베이스와 인덱스로 주소를 구하고 정확히 한 번 전송한다. Rn 31은 SP, Rm 31은 ZR, Vt 31은 SIMD 데이터 레지스터다. 베이스 writeback이 없고 scalar SIMD load는 상위 비트를 0으로 만든다.
- 새 Pcode의 목적지 정보를 갱신했다. CCMP는 기존 GPR 문자열 provenance를 보존하고 SMULH가 목적지를 덮어쓰면 오래된 문자열 추론을 폐기한다. 새 public enum variant를 exhaustive match하는 외부 Rust 코드는 갱신이 필요하다.

**직전 보고서 정정:** `libchannels.so:0x80618`, 워드 `0x3ca96ac0`은 `LDR`이 아니라 실제로 `STR Q0, [X22, X9]`다. 원본 ELF의 objdump로 확인했다. 해당 중단점을 해결하기 위해 load와 store를 함께 구현하고 저장 후 메모리까지 검증했다. 과거 보고서는 당시 기록으로 보존한다.

## 실제 입력에서의 진행량

| 양쪽에 적용한 예산 | 진입점 수 | 지원 범위 내 종료, 이전→수정 | 출력 명령 수 합, 이전→수정 |
| --- | ---: | ---: | ---: |
| 128 | 172 | 146→146 | 5,067→5,067 |
| 512 | 172 | 158→162 | 7,363→7,676 |
| 2,048 | 172 | 162→166 | 8,303→8,645 |

출력 명령 수는 진입점별 CFG의 합으로, 진입점 사이의 중복 코드가 포함된다. 전체 프로세스의 실행 명령 수나 유일한 코드 커버리지 비율을 뜻하지 않는다. 외부 함수 호출은 opaque call로 남는다. 지원 범위 내 종료는 이번 정적 CFG에서 예산/미지원/미해결 분기로 중단되지 않았다는 뜻이다.

2,048개 예산에서 바뀐 여섯 진입점:

| ELF / 진입점 / 함수 | 출력 명령 수 | 종료 코드 | 이전 중단 명령 |
| --- | ---: | ---: | --- |
| image_processing / `0x6a3c` / nativeRotateYUV | 275→541 | 2→2 | CCMP, 네 CFG 경로 |
| channels / `0x86214` / nativeFileDownload | 214→223 | 2→0 | `0x80a9c: 0x9b4a7d29` SMULH |
| channels / `0x87aa8` / getAvatar | 168→194 | 2→2 | `0x80618: 0x3ca96ac0` STR Q register-offset |
| channels / `0x87acc` / nativeGetMessages | 161→175 | 2→0 | `0x814c0: 0xfa401924` CCMP |
| channels / `0x87ad0` / nativeLoadHistoryMessages | 195→209 | 2→0 | `0x80e54: 0xfa401924` CCMP |
| channels / `0x87ad4` / nativeLoadNewMessages | 171→184 | 2→0 | `0x811e8: 0xfa401924` CCMP |

Hopper 98개 진입점은 세 예산 모두 결과가 완전히 같다. 2,048개 예산에서는 98→98개 지원 범위 내 종료, 출력 명령 합 3,769→3,769다. release metadata probe에서도 selector 51개, 검증된 ObjC stub 50개를 유지했다. counter 31개 진입점도 전부 이전과 같다. 기존 ART 캡처 네 개를 다시 제공한 회귀 12쌍에서는 각각 23개 명령·종료 0 및 ThrowNew tailcall을 유지했다. 이번에는 Android 런타임 캡처를 새로 수집하지 않았다.

## 실제 ARM64 CPU와 의미 비교

ARM64 Mac에서 [native.s](native.s)의 2,744개 fixture를 dylib로 빌드하여 실제 명령을 실행했다. CPU의 결과와 같은 워드를 디코딩한 Pcode 실행 결과를 [verify_native.py](verify_native.py)로 비교했다. 최종 release reference에서 **250,688건 전부 통과**했다.

| 검증 종류 | 사례 수 |
| --- | ---: |
| CCMP/CCMN 모든 폭·형식·조건·fallback | 229,376 |
| 비교의 ZR/imm0 경계 | 5,376 |
| SMULH signed 경계·난수·별칭 | 9,312 |
| SIMD 모든 폭·확장·스케일·load/store·SP/ZR/V31 | 6,400 |
| CCMP→CCMN→B.GT 연속 실행 | 224 |

16개 조건 코드, 입력 NZCV 16종, fallback NZCV 16종을 포함한다. 연속 실행은 실제 두 분기 결과 `0x11`과 `0x22`를 모두 확인했다. GPR/SP, NZCV, V0/V31의 전체 128비트, 대상 메모리 전체, 전송 횟수와 writeback 부재를 비교했다. 작은 SIMD load의 상위 비트가 남는 오류도 탐지하도록 nonzero 벡터를 먼저 넣었다. 4,096건 이하로 나눈 62개 batch로 검사했다.

추가 검증: 디버그 전체 **140개**, 관련 릴리스 **28개** 테스트 통과. `cargo clippy --all-targets -- -D warnings`, `cargo fmt --check`, `git diff --check` 통과. 예약 인코딩과 다른 명령군은 Unsupported로 남는지 검사했다. 예산 1/6의 CCMP CFG 테스트는 조건의 양쪽 경로와 작업 상한을 확인한다.

ISA 인코딩의 보조 근거는 [LLVM AArch64 assembler 테스트](https://github.com/llvm/llvm-project/blob/main/llvm/test/MC/AArch64/basic-a64-instructions.s)이며, 실행 의미의 독립 기준은 위 실제 CPU 결과다. 원본 Hopper/Android 앱 전체를 이번에 실행한 것은 아니다. 원본 바이너리에서는 정적 분석 진행량을, 직접 작성한 네이티브 fixture에서는 명령 의미를 검증했다.

## 남은 중단점

2,048개 예산의 여섯 미완료 진입점은 다음과 같다. 다음 명령을 구현한 것처럼 표시하거나 알 수 없는 간접 대상을 추측하지 않는다.

| 입력 / 진입점 | 중단 원인 |
| --- | --- |
| counter / `0xd80` | 캡처 없는 JNI `BR x3`; 기존 검증된 ART 캡처를 제공하면 위와 같이 지원 범위 내 종료 |
| counter / `0xd50` | 런타임 간접 `x16` |
| counter / `0x10c0` | PLT resolver 런타임 간접 `x17` |
| image_processing / `0x6a3c` | SMADDL `0x2944`, `0x2a68`, `0x6ea8`, `0x6fe4`, `0x7100`; SMULL 별칭 `0x6ed4`, `0x7010`, `0x712c` |
| image_processing / `0x719c` | nativeNewDirectByteBuffer의 간접 `x3` |
| channels / `0x87aa8` | `0x80680: 0x0f000600`, `MOVI V0.2S, #0x10` |

위 SMADDL/SMULL/MOVI 이름은 원본 ELF objdump와 대조했다. 모든 중단 워드·주소·이전/수정 비용과 상태는 [verification.json](verification.json)에 보존했다. 이전보다 명령 수가 줄거나 정상 종료가 실패로 바뀐 비교는 없다.

## 빌드 식별 및 재현

기준 실행 파일 SHA-256: `6d7f848b6d96f68f9c148b1ff98ad945220c1ef458a146cca048198ef6373059`.

최종 release·설치본 SHA-256: `fadd1b3e30cb033d177fc39f9f748d3874e452dda11cfc8b5bb66938dcc340e5`.

기준 보존본: `/Users/gimhyegon/Desktop/REA_Analysis/outputs/ghidra-hopper-rs-ccmp-smulh-20261031/ghidra-hopper-rs.before-ccmp-smulh`.

설치본 `/Users/gimhyegon/.local/bin/ghidra-hopper-rs`를 release와 같은 해시로 갱신하고 Hopper 진입점 및 변경된 Android 여섯 진입점의 명령 수·종료 상태를 재확인했다. 입력 경로와 SHA-256은 [직전 입력 식별 표](../wide/REPORT.md#빌드-및-입력-식별) 및 verification.json과 같다. 상용 바이너리·pulled ART·생성 dylib는 커밋하지 않는다.

ARM64 Mac, Rust, Python 3, Xcode clang/objdump/nm이 필요하다. ART 캡처 회귀에는 [기존 런타임 검증 환경](../jni_runtime/REPORT.md)의 해당 libart.so 이미지도 있어야 한다.

```sh
cargo test
cargo clippy --all-targets -- -D warnings
cargo fmt --check
cargo build --release
cargo build --release --example remaining_reference --example metadata_probe
cargo test --release --test conditional_compare --test wide --test ldrh_register --test remaining_paths --test jni_runtime
mkdir -p validation/conditional_compare/build
clang -arch arm64 -dynamiclib validation/conditional_compare/native.s \
  -o validation/conditional_compare/build/native.dylib
python3 validation/conditional_compare/verify.py \
  --baseline /path/to/ghidra-hopper-rs.before-ccmp-smulh \
  --candidate target/release/ghidra-hopper-rs \
  --hopper "/Applications/Hopper Disassembler.app/Contents/MacOS/hopper" \
  --elf-dir /path/to/mt5/lib/arm64-v8a \
  --native validation/conditional_compare/build/native.dylib \
  --reference target/release/examples/remaining_reference
```

검증 스크립트의 표준 출력은 516개 비교 행과 native 검증 결과를 포함한 JSON이며, 이번 저장 결과가 verification.json이다.
