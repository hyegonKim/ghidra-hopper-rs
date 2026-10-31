# Hopper 및 Android ELF 분석 범위 확장

2026-10-31. 기준 커밋 `eaced05140642ffd9e012f58ea2a8eccd33a20f2`와 변경 release를 비교했습니다. 양쪽 모두 v0.3.0이므로 실행 파일 SHA-256으로 빌드를 구분합니다.

## 결과

Hopper 1개와 Android ELF 6개에서 **172개 진입점 × 128/512/2,048개 명령 예산 = 516쌍**을 같은 조건으로 비교했습니다. 이전에 검증한 29개보다 **143개 진입점**을 추가했습니다.

2,048개 예산에서 종료 코드 0인 진입점은 **146→162/172개**, 각 독립 분석의 출력 명령 수 합은 **6,617→8,303개**입니다. 합계에는 서로 다른 진입점에서 겹치는 코드가 포함되며, 바이너리 전체의 고유 코드 커버리지나 실행 횟수를 뜻하지 않습니다.

Hopper는 기존 함수들의 명령 수를 유지하면서 selector 참조 **51개**를 Apple `dyld_info -arch arm64 -fixups`와 대조했고, 완전히 검증된 Objective-C 스텁 이름은 **0→50개**로 늘었습니다. 단순히 명령 수를 늘리기 위해 인접 함수·미확인 경로를 연결하지 않았습니다.

| 예산 | 종료 코드 0: 기준→변경 | 출력 명령 수 합: 기준→변경 |
| --- | ---: | ---: |
| 128 | 134→146 / 172 | 3,892→5,067 |
| 512 | 142→158 / 172 | 5,677→7,363 |
| 2,048 | 146→162 / 172 | 6,617→8,303 |

종료 코드 0은 **지원 범위의 정적 CFG 분석**입니다. 외부·내부 opaque 호출의 본문까지 분석하거나 완전한 SSA/의미 동등성을 증명한 것은 아닙니다.

## 표본 선정

- Hopper: 기존 함수 시작점 17개, canonical import 스텁 31개, Objective-C 스텁 50개 = 98개.
- 기존 counter ELF: 기존 12개, 비공개 init/fini helper 4개, PLT 스텁 14개와 동적 resolver 헤더 1개 = 31개.
- `libsurface_util_jni.so`: JNI export 1개 전부.
- `libimage_processing_util_jni.so`: JNI export 8개 전부.
- `libbarhopper_v3.so`: JNI export 8개 전부.
- `libchannels.so`: JNI export 15개 중 주소순으로 균등 선정한 12개.
- `libcommon.so`: JNI export 181개 중 주소순 균등 12개와 JNI_OnLoad/OnUnload 2개 = 14개.

입력 해시와 표본 선정 규칙을 검증 스크립트에 고정했습니다. 표본의 성공을 모든 export·내부 함수의 성공으로 일반화하지 않습니다.

## 구현한 명령과 의미

- **AND/ANDS/EOR immediate·shifted register, BIC/BICS/ORN/EON shifted register**: LSL/LSR/ASR/ROR 후 inversion과 논리 연산을 수행합니다. ANDS/TST·BICS는 N/Z를 결과에서 만들고 C/V를 0으로 설정합니다. 일반 연산은 NZCV를 보존합니다. logical immediate의 SP 목적지, register 형식의 ZR 목적지, W 쓰기의 상위 비트 제거를 구분합니다. 기존 ORR IR/API는 유지했습니다.
- **SUB shifted register 및 ADD/SUB extended register**: UXT[B/H/W/X], SXT[B/H/W/X], shift 0..4, flag-setting 형식과 CMP/CMN alias를 지원합니다. 확장 후 shift하고, ADD/SUB의 carry/no-borrow와 signed overflow를 구분합니다. SP와 ZR은 인코딩 문맥에 따라 처리합니다.
- **CSINC/CSINV/CSNEG**: 조건이 거짓일 때만 false operand를 증가·반전·부호 반전합니다. CSET/CSETM 등의 alias도 같은 인코딩으로 동작하며 NZCV를 보존합니다.
- **MADD/MSUB 및 MUL/MNEG alias**: 32/64비트 wrapping multiply-add/subtract, addend의 ZR, 버리는 목적지와 입력/목적지 alias를 처리합니다.
- **SIMD B/H/S/D/Q LDR/STR**: unsigned immediate와 signed unscaled/pre/post-index를 구현했습니다. **S/D STP/LDP**도 기존 Q pair와 함께 지원합니다. 정수 레지스터와 SIMD 레지스터는 별도 상태이며 scalar load는 상위 SIMD 비트를 0으로 만듭니다. store는 하위 해당 크기만 기록합니다. FP 산술이나 형 변환으로 표현하지 않습니다.

새 scalar 목적지들은 공통 `value_destination`에 연결했습니다. 이들 명령이 문자열·주소를 덮어쓴 뒤 예전 값이 살아 있는 것처럼 Objective-C 인자를 추론하지 않도록 회귀 테스트했습니다. SIMD store도 기존 JNI 문맥의 메모리 변경 검사에 반영했습니다.

## Hopper 정확성 수정

`LC_DYLD_CHAINED_FIXUPS`의 starts-in-image/segment와 page chain을 실제로 순회합니다. 이번 범위는 **DYLD_CHAINED_PTR_64(2), DYLD_CHAINED_PTR_64_OFFSET(6)의 single-start chain**입니다. next stride, 페이지·파일 경계, segment offset, 중복 위치·metadata 겹침과 reserved bits를 검사합니다. 체인에 포함되지 않은 값의 하위 비트를 임의로 포인터로 만들지 않습니다.

bind는 런타임 주소로 바꾸지 않습니다. uncompressed chained import 형식 1/2/3의 심볼·라이브러리 ordinal을 읽고, GOT 슬롯의 chain binding이 기존 indirect/nlist metadata와 일치해야 import로 인정합니다. weak/special ordinal·nonzero addend·지원하지 않는 이름 압축/포맷은 강한 binding으로 승격하지 않습니다.

selector 이름은 검증된 rebase가 실제 mapped `__objc_methname` 문자열을 가리킬 때만 복원합니다. **ADRP/LDR 두 명령의 prefix만으로 ObjC 호출이라고 판단하던 부분을 제거**했습니다. 전체 5개 명령, selref, GOT의 실제 chain binding과 libobjc의 strong `_objc_msgSend`가 일치해야 호출 이름을 부여합니다.

로드한 프로그램의 바이트·주소·파일 매핑·권한 fingerprint도 보존합니다. selector slot 자체가 같더라도 앞쪽 chain link가 바뀌면 옛 증명은 무효화합니다. import 및 비복귀 호출도 변경된 입력의 오래된 binding을 재사용하지 않습니다. fingerprint는 함수당 한 번 계산해 스텁별 전체 파일 재해시를 피합니다. 이 검사는 보수적이므로 분석용 바이트를 변경하면 metadata를 다시 로드해야 합니다.

Hopper의 selector 참조 **51/51개**는 `dyld_info`의 rebase 대상 문자열과 모두 일치했고, 스텁 **50/50개**의 이름·selref·unslid string target도 대조했습니다. 런타임 SEL/IMP 주소와 receiver class는 추측하지 않습니다.

형식 근거는 [Apple dyld fixup-chains.h](https://raw.githubusercontent.com/apple-oss-distributions/dyld/main/include/mach-o/fixup-chains.h), 명령 인코딩은 [LLVM AArch64 MC 테스트](https://raw.githubusercontent.com/llvm/llvm-project/main/llvm/test/MC/AArch64/basic-a64-instructions.s)를 대조했습니다. 명령 결과는 별도의 실제 CPU 실행으로 검증했습니다.

## 바이너리별 비교: 예산 2,048

| 바이너리 | 진입점 수 | 종료 코드 0: 기준→변경 | 출력 명령 수 합: 기준→변경 |
| --- | ---: | ---: | ---: |
| hopper | 98 | 98→98 | 3769→3769 |
| counter | 31 | 28→28 | 258→258 |
| libsurface_util_jni.so | 1 | 1→1 | 50→50 |
| libimage_processing_util_jni.so | 8 | 1→6 | 577→914 |
| libbarhopper_v3.so | 8 | 7→8 | 268→307 |
| libchannels.so | 12 | 4→7 | 665→1728 |
| libcommon.so | 14 | 7→14 | 1030→1277 |

## 분석이 더 진행된 진입점

동일 파일·진입점·2,048개 예산의 결과입니다. 종료 코드 2인 행은 진행량이 증가해도 남은 불확실성을 유지합니다.

| 바이너리 | 진입점 | 출력 명령: 기준→변경 | 종료 코드: 기준→변경 |
| --- | --- | ---: | ---: |
| libimage_processing_util_jni.so | `0x60cc` | 42→60 | 2→0 |
| libimage_processing_util_jni.so | `0x61bc` | 61→135 | 2→0 |
| libimage_processing_util_jni.so | `0x6540` | 124→237 | 2→0 |
| libimage_processing_util_jni.so | `0x68f4` | 81→82 | 2→0 |
| libimage_processing_util_jni.so | `0x6a3c` | 152→275 | 2→2 |
| libimage_processing_util_jni.so | `0x7154` | 16→18 | 2→0 |
| libimage_processing_util_jni.so | `0x719c` | 11→17 | 2→2 |
| libbarhopper_v3.so | `0xe1958` | 68→107 | 2→0 |
| libchannels.so | `0x57e44` | 15→51 | 2→0 |
| libchannels.so | `0x677e8` | 30→127 | 2→0 |
| libchannels.so | `0x86214` | 28→214 | 2→2 |
| libchannels.so | `0x87aa8` | 17→168 | 2→2 |
| libchannels.so | `0x87abc` | 55→130 | 2→0 |
| libchannels.so | `0x87acc` | 3→161 | 2→2 |
| libchannels.so | `0x87ad0` | 3→195 | 2→2 |
| libchannels.so | `0x87ad4` | 3→171 | 2→2 |
| libcommon.so | `0x29cc24` | 64→109 | 2→0 |
| libcommon.so | `0x29dc68` | 8→10 | 2→0 |
| libcommon.so | `0x29e44c` | 39→49 | 2→0 |
| libcommon.so | `0x29e6b0` | 37→48 | 2→0 |
| libcommon.so | `0x29fdf8` | 24→91 | 2→0 |
| libcommon.so | `0x2a1eb8` | 25→129 | 2→0 |
| libcommon.so | `0x2a5eec` | 2→10 | 2→0 |

Hopper main `0x100002ddc`의 호출자 명령 1,121개와 bounded callee proof를 포함한 작업 비용 1,945개는 유지됩니다. 이전에 잘못 포함됐던 `0x100003f60`을 main 경로로 다시 연결하지 않았습니다. 이번 Hopper의 개선은 selector/호출 식별과 검증 범위 확대입니다.

## 검증

- **디버그 테스트 133개**, 릴리스 주요 테스트 **46개**, Clippy `--all-targets -- -D warnings`, rustfmt 통과.
- **841개 native fixture / 24,928건 CPU↔IR 대조**: logical 10,752, conditional transform 6,144, extended arithmetic 2,560, shifted SUB 1,152, multiply-add 512, SP/ZR edge 1,088, immediate 1,152, SIMD memory 1,568건.
- 실제 ARM64 CPU의 결과 GPR/SP, SIMD bit pattern·상위 비트 초기화, NZCV, 전체 대상 메모리와 전송 횟수를 비교했습니다. native wrapper의 초기화·결과 수집은 IR 명령 비용에 포함하지 않으며, 대조 대상은 추출한 단일 명령입니다.
- Foundation을 사용하는 자체 ObjC fixture를 컴파일·실행해 dispatch **8건**을 확인했습니다. fixture의 selector/stub도 `dyld_info`와 대조했습니다.
- 이전 실제 Android ART 캡처를 제공한 JNI 분석 **12쌍**도 기준과 동일한 23개·종료 코드 0을 유지했습니다. 캡처 없는 counter JNI는 계속 INCOMPLETE입니다.
- chained import 불일치·weak/addend·미지원 압축, malformed table/step, prefix-only 가짜 스텁, 변경된 selector/코드/상류 chain, reserved opcode와 stale-string inference를 테스트했습니다.

기존 EOR/SUB/CSINC/S/D pair의 “미지원” 전제는 새 구현 때문에 더 이상 유효하지 않습니다. 해당 negative 테스트는 여전히 미지원인 UDIV·non-temporal 형식 또는 reserved encoding으로 바꾸고, 새 기능은 별도 positive·CPU 대조 테스트로 검증했습니다.

이번 라운드에서 원본 Hopper 앱이나 Android 앱/라이브러리 프로세스 전체를 실행하지는 않았습니다. 원본은 **정적 분석 입력**으로 사용했고, 실행 검증은 명령 fixture와 자체 ObjC fixture에서 수행했습니다. 보존된 ART 캡처의 회귀 검증을 새 런타임 관찰로 표시하지 않습니다.

## 남은 중단점: 예산 2,048

| 바이너리 | 진입점 | 남은 미지원 또는 미해결 분기 |
| --- | --- | --- |
| counter | `0xd80` | 간접 분기 `x3` |
| counter | `0xd50` | 간접 분기 `x16` |
| counter | `0x10c0` | 간접 분기 `x17` |
| libimage_processing_util_jni.so | `0x6a3c` | `0x2860: 0xfa4008c4`, `0x298c: 0xfa4008c4`, `0x6de4: 0x7a4129e0`, `0x6f20: 0x7a412aa0` |
| libimage_processing_util_jni.so | `0x719c` | 간접 분기 `x3` |
| libchannels.so | `0x86214` | `0x80a9c: 0x9b4a7d29` |
| libchannels.so | `0x87aa8` | `0x80618: 0x3ca96ac0` |
| libchannels.so | `0x87acc` | `0x814c0: 0xfa401924` |
| libchannels.so | `0x87ad0` | `0x80e54: 0xfa401924` |
| libchannels.so | `0x87ad4` | `0x811e8: 0xfa401924` |

CCMP, SMULH, SIMD register-offset LDR 등은 이번 범위 밖입니다. PLT resolver의 런타임 linker 포인터와 임의 callback/JNI 테이블은 정적 값으로 만들지 않았습니다. ARM64e authenticated chain, MULTI start chain, 압축 import 이름과 일부 nonzero addend도 미지원 상태를 유지합니다.

## 빌드 및 입력 식별

기준 실행 파일 SHA-256: `f60930bb9ffadf2de9259bb44ebf8e92141a308e7e857e41c52d5a43cb651606`.

변경 release·설치본 SHA-256: `6d7f848b6d96f68f9c148b1ff98ad945220c1ef458a146cca048198ef6373059`.

| 입력 | SHA-256 |
| --- | --- |
| hopper | `dad6f886261fad0d4cdd01aee6fcf57439c60d7b5c54e62fc97f0180116690e0` |
| counter | `d3e48717c9aa147e0ab21063ba0e8e0211cabf8bf40b222640829519edbf58e1` |
| libsurface_util_jni.so | `a5c9d1928ea92ec7a94dff8cf666e7739cd734198b9f0ae1d4e28ea3c86516ba` |
| libimage_processing_util_jni.so | `0292b063fafccf734472cbb59588e756c2dbca907c72021ba6fbf126385508a2` |
| libbarhopper_v3.so | `ec09597e9eb3aee0eb55ae3366da0d4ba416f5aa35a1af0b3811f50ff46743a1` |
| libchannels.so | `2919908d8fdb418946e409425260ac3626381091500c0f8ffc513882ab35b92c` |
| libcommon.so | `8cdda58f37b8b2d0fab6646fcd08d57dee7cae418fec5226ff71f8e4e21ce364` |

Android 입력 디렉터리는 `/Users/gimhyegon/Desktop/REA_Analysis/outputs/metatrader-4-5-20261029/mt5/lib/arm64-v8a`, Hopper는 `/Applications/Hopper Disassembler.app/Contents/MacOS/hopper`입니다. 기준 보존본은 `/Users/gimhyegon/Desktop/REA_Analysis/outputs/ghidra-hopper-rs-wide-20261031/ghidra-hopper-rs.before-wide`입니다. 상용 입력 바이너리·pulled ART·생성 dylib는 커밋하지 않습니다.

[verification.json](verification.json)의 `entries`가 전체 172개 진입점을, `columns`가 516개 비교 행의 필드를 정의합니다. 명령 수 외에 비용, 상태, 미지원 워드·주소, 미해결 레지스터와 ObjC 식별 수를 보존했습니다. 과거 보고서는 당시 결과로 유지했습니다.

## 재현

ARM64 Mac, Rust, Python 3, Xcode clang/dyld_info가 필요합니다. 이전 JNI 캡처 회귀에는 `validation/jni_runtime/REPORT.md`의 방법으로 얻은 해당 ART 이미지도 필요합니다.

```sh
cargo test
cargo clippy --all-targets -- -D warnings
cargo fmt --check
cargo build --release
cargo build --release --example remaining_reference --example metadata_probe
cargo test --release --lib --test wide --test objc_tail --test regressions --test jni_runtime --test macho_import
mkdir -p validation/wide/build
clang -arch arm64 -dynamiclib validation/wide/native.s -o validation/wide/build/native.dylib
clang -arch arm64 -dynamiclib -fobjc-arc -fobjc-msgsend-selector-stubs \
  -framework Foundation validation/remaining_paths/objc_probe.m \
  -o validation/wide/build/objc.dylib
python3 validation/wide/verify.py \
  --baseline /path/to/ghidra-hopper-rs.before-wide \
  --candidate target/release/ghidra-hopper-rs \
  --hopper "/Applications/Hopper Disassembler.app/Contents/MacOS/hopper" \
  --elf-dir /path/to/mt5/lib/arm64-v8a \
  --metadata target/release/examples/metadata_probe \
  --native validation/wide/build/native.dylib \
  --reference target/release/examples/remaining_reference \
  --objc validation/wide/build/objc.dylib
```

Rust API에는 새 Pcode variant와 selector/import proof 필드가 추가됐습니다. 외부 코드에서 해당 enum을 exhaustive match하거나 public struct literal을 직접 생성했다면 갱신이 필요합니다.
