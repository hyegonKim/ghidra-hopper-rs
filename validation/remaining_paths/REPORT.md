# 남은 진입 경로 구현 및 동일 조건 검증

2026-10-31, ARM64 Mac / macOS 27.0.1 / rustc 1.93.1 / Apple clang 21.0.0.

기준은 `982c26f28bb8e3a05ede9502eb64892512697dd1`에서 설치한 v0.3.0이며, 변경본도 v0.3.0입니다. 버전 문자열 대신 실행 파일 SHA-256으로 비교 대상을 구분했습니다. Hopper LC_FUNCTION_STARTS 17개, Android ELF의 정의된 FUNC export 9개와 제어 진입점·실패 블록·atomic helper 3개, 총 29개를 사용했습니다. 두 버전 모두 같은 파일·진입점에 128/512/2,048개 예산을 적용한 87쌍입니다.

## 결과

2,048개 예산에서 종료 코드 0인 진입점은 **21→28/29개**, 출력되는 호출자 명령의 합은 **3,036→3,601개**입니다. 남은 하나는 Android `0xd80`의 런타임 JNI 테이블을 통한 `BR x3`입니다. 해당 대상은 파일만으로 확정할 수 없어 종료 코드 2를 유지합니다.

- Hopper `0x100000a60`: **121→173개**, MOVI와 SIMD pair를 통과합니다.
- Hopper `0x100001740`: **529→824개**, register-offset 정수 전송을 통과하고 libSystem의 `_exit`에서 각 종단 경로를 종료합니다.
- Hopper `0x1000025ec`: **34→247개**.
- Hopper `0x100000a58`: **7→7개**, 미해결 `BR x16`을 검증된 Objective-C import tail call로 바꿔 종료 코드 2→0. selector 이름과 런타임 주소는 미확인입니다.
- Android atomic helper `0xff0`: **7→12개**, LSE와 exclusive 재시도 경로 모두 해석하고 종료 코드 2→0.
- Hopper main `0x100002ddc`: 호출자 **1,121→1,121개**, 종료 코드 2→0. callee 824개를 추가 검증해 총 작업 **1,945개**를 사용합니다. 이전에 잘못 포함됐던 `0x100003f60`은 다시 포함하지 않습니다.

| 예산 | 기준 종료 코드 0 | 변경본 종료 코드 0 | 기준 출력 명령 합 | 변경본 출력 명령 합 |
| --- | ---: | ---: | ---: | ---: |
| 128 | 17/29 | 19/29 | 1,365 | 1,471 |
| 512 | 21/29 | 25/29 | 2,410 | 2,680 |
| 2,048 | 21/29 | 28/29 | 3,036 | 3,601 |

출력 명령 수는 양쪽 조건 분기를 포함한 CFG의 정적 명령 수입니다. 실행 횟수나 성능 수치가 아닙니다. 종료 코드 0도 지원 범위 분석임을 뜻하며 전체 프로그램·외부 호출의 의미 동등성을 보증하지 않습니다.

## 구현과 정확성

- bitmask MOVI D/V.2D: 8비트 immediate의 각 비트를 0x00/0xff 바이트로 확장합니다. D 쓰기는 상위 64비트를 0으로 만들고 Q/V 상태는 GPR/SP/ZR과 별도로 보존합니다.
- 128비트 SIMD STP/LDP: offset/pre/post-index, signed imm7×16과 writeback을 구현했습니다. Q31은 SIMD 데이터 레지스터입니다. 주소를 먼저 캡처하며 중복 LDP 목적지는 지원하지 않습니다.
- 정수 register-offset LDRB/LDRH/LDR/STRB/STRH/STR와 LDRSW: UXTW/UXTX/SXTW/SXTX 후 width에 따른 scaling, W zero-extension/LDRSW sign-extension, SP·ZR와 목적지/주소 alias를 처리합니다.
- 32/64비트 LDADD/LDADDA/LDADDL/LDADDAL: 원자적 read-modify-write와 반환되는 이전 값을 IR에 명시합니다. acquire/release를 보존하며 일반 LOAD+STORE로 바꾸지 않습니다.
- 32/64비트 LDAXR/STLXR/CLREX: exclusive reservation과 실패 시 무쓰기, status 0/1, 매 시도 reservation 소비, spurious failure 가능성을 IR에 명시합니다. opaque 호출 후 monitor는 미확인입니다.
- 호출 후 SIMD 상태: base AAPCS64에 따라 V0–V7/V16–V31과 V8–V15의 상위 64비트를 미확인으로 두며 V8–V15의 하위 64비트는 보존합니다.
- 32바이트 `__objc_stubs`: 전체 ADRP X1/LDR X1/ADRP X16/LDR X16/BR X16과 mapped selref, GOT 간접 심볼 및 `/usr/lib/libobjc.A.dylib`의 strong undefined `_objc_msgSend`를 대조합니다. 두 번째 ADRP의 PC가 다른 페이지에 있을 수 있는 점도 처리합니다. 전체 5개 명령이 같은 분석 블록에 없거나 파일 코드가 변경되면 proof를 재사용하지 않습니다. chained pointer의 파일 값을 런타임 selector/함수 주소로 사용하지 않습니다.
- 비복귀 callee 증명: 알려진 libSystem `_exit`/stack failure import 또는 검증된 ELF stack failure call에서 종료되는 완전 CFG만 증거로 인정합니다. RET, 미지원 명령, 미확인 분기·경계 또는 종단 없는 loop는 증거가 될 수 없습니다. 경계를 넘는 호출의 선언된 직접 callee만 한 단계 분석하고 caller를 다시 디코딩하지 않습니다. 제거된 명령의 byte-state·참조도 복구합니다.

callee 증명에 성공하거나 실패한 모든 비용은 원래 예산에서 차감합니다. `Instruction work`와 `Nonreturn proof`로 출력하며 87건 모두 비용≤예산을 단언했습니다.

| 호출자 | 예산 | 호출자 출력 | callee 작업 | 증명 | 전체 비용 |
| --- | ---: | ---: | ---: | --- | ---: |
| `0x100002cf0` | 128 | 59 | 69 | 실패, INCOMPLETE 유지 | 128 |
| `0x100002cf0` | 512 | 59 | 453 | 실패, INCOMPLETE 유지 | 512 |
| `0x100002cf0` | 2,048 | 59 | 824 | 성공 | 883 |
| `0x100002ddc` | 2,048 | 1,121 | 824 | 성공 | 1,945 |

## 전체 진입점 비교

각 셀은 `명령 수/종료 코드`의 기준→변경본입니다.

| 바이너리 / 진입점 | 예산 128 | 예산 512 | 예산 2,048 |
| --- | --- | --- | --- |
| Hopper `0x100000a58` | `7/2 → 7/0` | `7/2 → 7/0` | `7/2 → 7/0` |
| Hopper `0x100000a60` | `121/2 → 128/2` | `121/2 → 173/0` | `121/2 → 173/0` |
| Hopper `0x100000d08` | `9/0 → 9/0` | `9/0 → 9/0` | `9/0 → 9/0` |
| Hopper `0x100000d20` | `26/0 → 26/0` | `26/0 → 26/0` | `26/0 → 26/0` |
| Hopper `0x100000d88` | `23/0 → 23/0` | `23/0 → 23/0` | `23/0 → 23/0` |
| Hopper `0x100000de4` | `24/0 → 24/0` | `24/0 → 24/0` | `24/0 → 24/0` |
| Hopper `0x100000e44` | `128/2 → 128/2` | `228/0 → 228/0` | `228/0 → 228/0` |
| Hopper `0x1000011c8` | `128/2 → 128/2` | `170/0 → 170/0` | `170/0 → 170/0` |
| Hopper `0x100001464` | `128/2 → 128/2` | `186/0 → 186/0` | `186/0 → 186/0` |
| Hopper `0x100001740` | `128/2 → 128/2` | `512/2 → 512/2` | `529/2 → 824/0` |
| Hopper `0x100002420` | `45/0 → 45/0` | `45/0 → 45/0` | `45/0 → 45/0` |
| Hopper `0x1000024c8` | `30/0 → 30/0` | `30/0 → 30/0` | `30/0 → 30/0` |
| Hopper `0x100002534` | `49/0 → 49/0` | `49/0 → 49/0` | `49/0 → 49/0` |
| Hopper `0x1000025ec` | `34/2 → 128/2` | `34/2 → 247/0` | `34/2 → 247/0` |
| Hopper `0x1000029bc` | `128/2 → 128/2` | `205/0 → 205/0` | `205/0 → 205/0` |
| Hopper `0x100002cf0` | `59/2 → 59/2` | `59/2 → 59/2` | `59/2 → 59/0` |
| Hopper `0x100002ddc` | `128/2 → 128/2` | `512/2 → 512/2` | `1121/2 → 1121/0` |
| Android `0xd80` | `23/2 → 23/2` | `23/2 → 23/2` | `23/2 → 23/2` |
| Android `0xddc` | `30/0 → 30/0` | `30/0 → 30/0` | `30/0 → 30/0` |
| Android `0xfc8` | `8/0 → 8/0` | `8/0 → 8/0` | `8/0 → 8/0` |
| Android `0xf44` | `9/0 → 9/0` | `9/0 → 9/0` | `9/0 → 9/0` |
| Android `0xe54` | `48/0 → 48/0` | `48/0 → 48/0` | `48/0 → 48/0` |
| Android `0xf68` | `22/0 → 22/0` | `22/0 → 22/0` | `22/0 → 22/0` |
| Android `0xf14` | `6/0 → 6/0` | `6/0 → 6/0` | `6/0 → 6/0` |
| Android `0xfc0` | `2/0 → 2/0` | `2/0 → 2/0` | `2/0 → 2/0` |
| Android `0xf2c` | `6/0 → 6/0` | `6/0 → 6/0` | `6/0 → 6/0` |
| Android `0xd30` | `8/0 → 8/0` | `8/0 → 8/0` | `8/0 → 8/0` |
| Android `0xf10` | `1/0 → 1/0` | `1/0 → 1/0` | `1/0 → 1/0` |
| Android `0xff0` | `7/2 → 12/0` | `7/2 → 12/0` | `7/2 → 12/0` |

## 실제 CPU 및 회귀 검증

- 디버그 테스트 **115개**, Clippy `--all-targets -D warnings`, rustfmt, 릴리스 주요 테스트 **29개** 통과.
- native ARM64와 실제 opcode를 리프팅한 IR 모델의 **4,560건** 대조: MOVI 2,048건(모든 imm8 및 D/Q), SIMD pair 96건(모든 NZCV), register-offset 1,440건, LSE 768건, exclusive loop 192건, CLREX 실패 16건. 결과 레지스터·SIMD halves·메모리·NZCV와 load/store 횟수를 확인했습니다.
- 추가 모델 **8건**에서 spurious 실패 1/3회와 간섭 쓰기를 주입해 재시도, 반환 이전 값, 최종 메모리, reservation 소비를 확인했습니다. 이 모델은 주소·크기·버전의 보수적 monitor이며 하드웨어 reservation granule/모든 메모리 순서를 에뮬레이션하지 않습니다.
- native LSE 및 exclusive loop 각각 **4스레드 × 2,000회 = 8,000회** 증가: 최종값 8,000, 반환 이전 값이 0..7,999의 중복 없는 집합임을 검증했습니다.
- Foundation Objective-C 라이브러리를 실제 컴파일·로드하고 dispatch 8건을 실행했습니다. 생성된 `_objc_msgSend$echo:` 5개 명령은 기준 종료 코드 2→변경본 0으로 해석됩니다. 실제 message 결과는 입력×3+7과 일치했습니다.
- 원본 Hopper/Android ELF는 분석 입력으로 사용했습니다. Hopper 앱이나 Android 프로세스 전체를 실행한 검증은 아닙니다.

negative 테스트에는 SIMD/GPR 분리·Q31/SP, scalar upper clear, 중복 pair 목적지, 잘못된 extension/SIMD·PRFM 오인식 거부, atomic alias·width·ordering, 잘못된 STLXR status overlap, 비복귀 증명 실패·비용 상한·가지치기 후 참조 정리, 잘못된 ObjC prefix/metadata/라이브러리, stub 중간 진입·부분 예산·변경된 코드와 ADRP 페이지 경계를 포함합니다.

구현 범위는 LLVM의 [기본 A64 MC 테스트](https://raw.githubusercontent.com/llvm/llvm-project/main/llvm/test/MC/AArch64/basic-a64-instructions.s)와 [ARMv8.1 atomics MC 테스트](https://raw.githubusercontent.com/llvm/llvm-project/main/llvm/test/MC/AArch64/armv8.1a-atomic.s)를 대조하고 네이티브 실행으로 확인했습니다.

## 입력과 빌드 식별

| 대상 | SHA-256 |
| --- | --- |
| Hopper Universal, ARM64 slice 선택 | `dad6f886261fad0d4cdd01aee6fcf57439c60d7b5c54e62fc97f0180116690e0` |
| Android ELF | `d3e48717c9aa147e0ab21063ba0e8e0211cabf8bf40b222640829519edbf58e1` |
| 기준 설치 실행 파일 | `5589509b71a847d86a871c4d59597b30ce10c2e87131d58fa66b3b24703babae` |
| 변경 release 실행 파일 | `094dcdf9d43a2b2395fc5c9e9bd4683ec999c4e7b39ce8f74b193b35151af9df` |

입력 경로:

- Hopper: `/Applications/Hopper Disassembler.app/Contents/MacOS/hopper`
- ELF: `/Users/gimhyegon/Desktop/REA_Analysis/outputs/metatrader-4-5-20261029/mt5/lib/arm64-v8a/libdatastore_shared_counter.so`
- 기준 보존본: `/Users/gimhyegon/Desktop/REA_Analysis/outputs/ghidra-hopper-rs-remaining-paths-20261031/ghidra-hopper-rs.before-remaining-paths`

원본 상용 바이너리·Android 라이브러리·생성 dylib는 커밋하지 않습니다. [verification.json](verification.json)에 87건의 상세 결과·추가/제거 주소·작업 비용·네이티브 검증 수를 보존했습니다. 이전 라운드 보고서는 당시 결과로 유지했습니다.

## 재현

ARM64 Mac, LSE 지원(`sysctl -n hw.optional.armv8_1_atomics`가 1), Xcode clang 및 Python 3가 필요합니다. 스크립트도 실행 전에 호스트와 LSE를 확인합니다.

```sh
cargo test
cargo clippy --all-targets -- -D warnings
cargo fmt --check
cargo build --release
cargo build --release --example remaining_reference
cargo test --release --test remaining_paths --test objc_tail --test bitfield_plt --test macho_import
mkdir -p validation/remaining_paths/build
clang -arch arm64 -march=armv8.1-a -dynamiclib \
  validation/remaining_paths/native.s validation/remaining_paths/stress.c \
  -o validation/remaining_paths/build/native.dylib
clang -arch arm64 -dynamiclib -fobjc-arc -fobjc-msgsend-selector-stubs \
  -framework Foundation validation/remaining_paths/objc_probe.m \
  -o validation/remaining_paths/build/objc.dylib
python3 validation/remaining_paths/verify.py \
  --baseline /path/to/preserved/ghidra-hopper-rs.before-remaining-paths \
  --candidate target/release/ghidra-hopper-rs \
  --hopper "/Applications/Hopper Disassembler.app/Contents/MacOS/hopper" \
  --elf /path/to/libdatastore_shared_counter.so \
  --native validation/remaining_paths/build/native.dylib \
  --reference target/release/examples/remaining_reference \
  --objc validation/remaining_paths/build/objc.dylib
```

## 남은 한계

JNI ThrowIoException `0xd80`의 `BR x3`는 런타임 JNIEnv 함수 테이블이 필요합니다. selector chained-fixup 이름과 외부 함수 본문·시그니처도 미복원입니다. LDADD no-result(Rt=31), byte/halfword atomics, 다른 LSE 연산, non-acquire LDXR, SIMD S/D pair와 non-temporal pair 등은 이번 범위 밖이며 미지원 상태를 유지합니다. 선택한 29개 진입점의 결과를 두 바이너리 전체의 완전 분석으로 확장해 해석하면 안 됩니다.
