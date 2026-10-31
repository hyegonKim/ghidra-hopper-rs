# 다른 Hopper·Android ELF 진입점의 버그 수정과 비교 검증

2026-10-31. Hopper의 다른 함수 시작점 16개와 Android export 9개를 조사하고, 기존 진입점 2개 및 보조 경로 2개를 포함한 **29개 진입점 × 예산 3종 = 87쌍**을 같은 조건으로 비교했습니다. 2,048개 예산에서 이전에 중단되던 함수 진입점 **10개(Hopper 7개·Android 3개)**가 지원 범위의 분석 결과를 반환합니다. 기존에 정상으로 표시되던 Hopper 두 진입점의 경계 오류도 바로잡아, 미확인 continuation은 `INCOMPLETE`로 남깁니다. 전체 프로그램 분석 완료를 뜻하지 않습니다.

## 변경

- **MOVN/MOVK:** 32/64비트, 16비트 단위 이동·보존과 W 결과의 상위 비트 제거, ZR 목적지의 버리는 쓰기를 구현했습니다. MOVZ도 같은 디코더에서 일관된 폭·ZR 규칙을 사용합니다.
- **CSEL:** 조건 코드 16종, NZCV 읽기·보존, W/X 및 ZR 입력과 버리는 목적지를 구현했습니다. CSINC/CSINV/CSNEG는 이번 지원 범위가 아닙니다.
- **LDRSW/LDURSW:** unsigned immediate와 signed unscaled/pre/post-index 형식을 구현했습니다. 먼저 원래 베이스로 주소를 계산해 4바이트를 읽고 64비트로 부호 확장합니다. writeback 중복은 거부하며 literal/register-offset 형식은 미지원입니다.
- **TPIDR_EL0:** 런타임의 스레드별 시스템 레지스터 읽기로 표현합니다. 0이나 파일 상수로 가정하지 않으며 다른 MRS 레지스터는 지원한 것으로 표시하지 않습니다.
- **LDAR:** 일반 레지스터 목적지의 32/64비트 acquire 읽기를 별도 IR로 구현했습니다. 일반 Load로 낮추지 않습니다. SP 베이스·목적지/베이스 겹침도 처리합니다. ZR 목적지, exclusive load/store 및 LSE RMW는 미지원입니다.

함께 수정한 정확성 문제:

1. **알려진 함수·섹션 경계를 넘는 가짜 도달 경로:** Mach-O LC_FUNCTION_STARTS와 ELF의 정의된 FUNC 심볼, 섹션 범위를 추적합니다. 일반 fall-through로 다른 함수를 붙이지 않고 `UnverifiedContinuation`으로 표시합니다. 명시적인 분기는 허용하며, 반환하지 않는다는 근거가 없는 호출을 임의로 NoReturn로 만들지 않습니다. LC_FUNCTION_STARTS의 ULEB128 절단·오버플로·정렬·실행 매핑도 검증합니다.

2. **반환하지 않는 호출 뒤의 잘못된 탐색:** 검증된 ELF `__stack_chk_fail`, libSystem의 Mach-O `___stack_chk_fail` import 호출에서 CFG를 종료합니다. Android `0xf10`에서 이전에는 호출 다음 JNI 함수의 6개 명령까지 포함해 7개를 정상 분석으로 표시했지만, 수정 후에는 실제 실패 블록의 호출 1개만 포함합니다. import 코드가 변경되면 이 근거를 재사용하지 않습니다. 동일 이름의 사설 Mach-O 라이브러리도 비반환 함수로 가정하지 않습니다.
3. **오래된 ELF PLT binding:** 로더에서 검증한 네 명령의 스냅샷과 현재 분석 코드가 일치해야 외부 호출 또는 비반환 호출로 해석합니다. stub 중간 진입과 코드 변경은 미해결 상태를 유지합니다.
4. **오래된 문자열 추론:** SUB 등 값 쓰기 뒤 이전 Objective-C 문자열 인자가 남던 문제를 수정했습니다. 공통 `value_destination()`를 사용해 새 명령도 상수/문자열·점프 테이블의 도달 정의를 올바르게 무효화합니다.
5. **ADDG/SUBG 오해석:** 일반 ADD/SUB immediate의 비트 마스크가 너무 넓어 tagged arithmetic과 예약 인코딩을 일반 덧셈/뺄셈으로 표시하던 문제를 수정했습니다. 미구현 형식은 `Unsupported`로 남깁니다.

참조: [LLVM AArch64 명령 인코딩 테스트](https://raw.githubusercontent.com/llvm/llvm-project/main/llvm/test/MC/AArch64/basic-a64-instructions.s), [Bionic stack-check 실패 구현](https://raw.githubusercontent.com/aosp-mirror/platform_bionic/master/libc/bionic/__stack_chk_fail.cpp). 비반환 분류는 플랫폼 import의 함수 계약에 따른 정적 분석이며 런타임 interposition까지 증명하는 것은 아닙니다.

## 비교 조건

- 기준 소스 커밋: `795da33`. 변경 전 설치본을 별도 보존했습니다.
- 기준 실행 파일 SHA-256: `ecfd0fe04eb2c3408594623df128d50790ecd85bb1e15cf587e1ceb33556552b`.
- 수정 후 release·설치본 SHA-256: `5589509b71a847d86a871c4d59597b30ce10c2e87131d58fa66b3b24703babae`.
- Hopper Universal의 ARM64 슬라이스, 파일 SHA-256: `dad6f886261fad0d4cdd01aee6fcf57439c60d7b5c54e62fc97f0180116690e0`.
- 기존 Android ARM64 ELF `libdatastore_shared_counter.so`, 파일 SHA-256: `d3e48717c9aa147e0ab21063ba0e8e0211cabf8bf40b222640829519edbf58e1`.
- 같은 파일과 진입점 각각에 **128·512·2,048개 명령 예산**을 적용했습니다. 파일 해시는 비교 전후에 확인했습니다.
- Hopper 진입점은 LC_FUNCTION_STARTS, Android 함수는 정의된 dynsym FUNC export에서 추출했습니다. 추가 `0xff0`은 직접 호출 대상인 atomic helper, `0xf10`은 실패 경로 블록입니다. 기존 Hopper `0x100002ddc`와 ELF `0xd30`도 회귀 비교했습니다.

탐색량은 여러 분기 경로의 디코딩 수이며 발견한 미지원 명령도 포함합니다. 종료 코드 0은 지원 범위 분석, 2는 예산 소진·미지원·미해결 분기가 남았다는 뜻입니다. 비반환 호출 뒤 명령 수가 줄어든 것은 잘못된 경로를 제거한 결과입니다.

## 2,048개 예산의 전체 결과

| 입력 | 진입점 | 이전 | 수정 후 | 종료 코드 | 해석 |
|---|---|---:|---:|---|---|
| Hopper | `0x100000a58` | 7 | 7 | 2→2 | ObjC stub의 BR x16 미해결 |
| Hopper | `0x100000a60` | 130 | 121 | 2→2 | SIMD MOVI 남음; 잘못된 fall-through 제거 |
| Hopper | `0x100000d08` | 9 | 9 | 0→0 | 지원 범위 결과 유지 |
| Hopper | `0x100000d20` | 8 | 26 | 2→0 | LDRSW 통과 |
| Hopper | `0x100000d88` | 8 | 23 | 2→0 | LDRSW 통과 |
| Hopper | `0x100000de4` | 8 | 24 | 2→0 | LDRSW 통과 |
| Hopper | `0x100000e44` | 210 | 228 | 2→0 | LDRSW 통과 |
| Hopper | `0x1000011c8` | 165 | 170 | 2→0 | MOVK 통과; 비반환 경로 교정 |
| Hopper | `0x100001464` | 98 | 186 | 2→0 | MOVK/CSEL 통과; 비반환 경로 교정 |
| Hopper | `0x100001740` | 28 | 529 | 2→2 | CSEL 통과; SIMD MOVI 남음 |
| Hopper | `0x100002420` | 72 | 45 | 0→0 | 비반환 호출 뒤 이웃 경로 제거 |
| Hopper | `0x1000024c8` | 30 | 30 | 0→0 | 지원 범위 결과 유지 |
| Hopper | `0x100002534` | 49 | 49 | 0→0 | 지원 범위 결과 유지 |
| Hopper | `0x1000025ec` | 34 | 34 | 2→2 | SIMD MOVI 남음 |
| Hopper | `0x1000029bc` | 202 | 205 | 2→0 | LDRSW 통과 |
| Hopper | `0x100002cf0` | 1183 | 59 | 0→2 | 다음 main을 붙이던 경로 제거; continuation 미확인 |
| Hopper | `0x100002ddc` | 1124 | 1121 | 0→2 | __stubs의 가짜 도달 경로 제거; continuation 미확인 |
| Android ELF | `0xd80` | 21 | 23 | 2→2 | MOVN 통과; JNI BR x3 미해결 |
| Android ELF | `0xddc` | 30 | 30 | 2→0 | MOVN 통과 |
| Android ELF | `0xfc8` | 8 | 8 | 0→0 | 지원 범위 결과 유지 |
| Android ELF | `0xf44` | 9 | 9 | 0→0 | 지원 범위 결과 유지 |
| Android ELF | `0xe54` | 6 | 48 | 2→0 | TPIDR_EL0/MOVN/CSEL 통과 |
| Android ELF | `0xf68` | 22 | 22 | 0→0 | 지원 범위 결과 유지 |
| Android ELF | `0xf14` | 6 | 6 | 0→0 | 지원 범위 결과 유지 |
| Android ELF | `0xfc0` | 1 | 2 | 2→0 | LDAR acquire 로드 |
| Android ELF | `0xf2c` | 6 | 6 | 0→0 | 지원 범위 결과 유지 |
| Android ELF | `0xd30` | 8 | 8 | 0→0 | 기존 기준 진입점 유지 |
| Android ELF | `0xf10` | 7 | 1 | 0→0 | 비반환 실패 블록 뒤 6개 제거 |
| Android ELF | `0xff0` | 7 | 7 | 2→2 | LDADDAL/LDAXR 미지원 |

대표 진입점의 예산별 결과입니다. 괄호 안은 종료 코드입니다.

| 진입점 | 128개 예산 | 512개 예산 | 2,048개 예산 |
|---|---|---|---|
| `0x100000d20` | 8→26 (2→0) | 8→26 (2→0) | 8→26 (2→0) |
| `0x100001464` | 98→128 (2→2) | 98→186 (2→0) | 98→186 (2→0) |
| `0x100001740` | 28→128 (2→2) | 28→512 (2→2) | 28→529 (2→2) |
| `0xe54` | 6→48 (2→0) | 6→48 (2→0) | 6→48 (2→0) |
| `0xfc0` | 1→2 (2→0) | 1→2 (2→0) | 1→2 (2→0) |
| `0xf10` | 7→1 (0→0) | 7→1 (0→0) | 7→1 (0→0) |
| `0x100002ddc` | 128→128 (2→2) | 512→512 (2→2) | 1124→1121 (0→2) |

전체 87쌍의 중단 opcode·미해결 레지스터·제거된 주소는 [verification.json](verification.json)에 있습니다. 기존 ELF 기준 진입점은 유지됩니다. Hopper main은 잘못 도달했던 import stub 3개를 제거해 1,121개·종료 코드 2로 교정됩니다.

## 검증

- `cargo test --quiet`: **103개 통과**, 실패 0개.
- `cargo test --release --test other_entries --test bitfield_plt --test macho_import`: 관련 **24개 통과**.
- `cargo clippy --all-targets -- -D warnings`, `cargo fmt --check`, `git diff --check`, release 빌드 통과.
- MOVK의 전체 16비트 immediate·모든 유효 shift/폭, CSEL의 모든 조건·NZCV 상태, ZR/SP와 부호 확장·주소 스냅샷·writeback 거부, 잘못된 인코딩, 문자열 추론과 stale binding, 비반환 호출의 경계를 테스트했습니다.
- [native.s](native.s)를 ARM64 dylib로 빌드해 CPU 결과와 [Rust IR 검증 도구](../../examples/other_reference.rs)의 결과를 **1,713건** 대조했습니다.

| 네이티브 검증 | 건수 | 확인 |
|---|---:|---|
| CSEL | 1,536 | 16조건 × 16 NZCV × 두 폭 × 세 입력쌍; 결과·NZCV 보존 |
| MOVN/MOVK | 96 | 두 폭·모든 halfword 위치·상위 비트·기존 값 보존 |
| LDRSW/LDURSW | 48 | 양수·음수·경계값, offset/pre/post, 베이스 겹침·버리는 쓰기, writeback |
| LDAR | 24 | 두 폭·SP·unsigned 결과·별도 acquire IR |
| TPIDR_EL0 | 9 | 실제 호스트 값 읽기·버리는 목적지; 스레드 레지스터를 쓰지 않음 |

메모리 검증은 단일 스레드의 값·주소 계산 대조이며 동시성 전체의 증명은 아닙니다. Acquire 속성은 IR에 보존하지만 exclusive monitor/RMW 실행기는 구현하지 않았습니다. TPIDR_EL0 값은 네이티브 관측값을 검증기에 제공합니다. Android 프로세스·JNI 환경이나 Hopper GUI 자체를 실행한 검증이 아닙니다.

### 이전 main 결과의 정정

이전 `0x100002ddc` 분석은 마지막 `0x100003f5c: BL 0x100001740` 다음으로 무관한 `__stubs`의 `0x100003f60..0x100003f68`까지 fall-through해 1,124개·종료 코드 0을 반환했습니다. `_CFRunLoopGetCurrent`라는 import 연결 자체는 맞지만 **main에서 그 stub으로 도달한다는 판단은 잘못됐습니다**. 수정 후 그 세 명령을 제외하고, 호출의 continuation을 검증하지 못했음을 명시해 1,121개·`INCOMPLETE`로 반환합니다. 개별 import stub 해석은 유지됩니다.

같은 문제로 `0x100002cf0` 뒤에 다음 main을 붙여 1,183개로 표시하던 경로는 59개·`INCOMPLETE`로 바뀝니다. 명령 수와 정상 종료를 억지로 늘리기보다, 확인된 도달 관계만 유지한 수정입니다.

## 남은 중단 원인

- Hopper `0x100002cf0`, main `0x100002ddc`: 내부 호출 뒤의 경계를 넘는 continuation이 미확인입니다. callee 전체의 비반환 성질을 추측하지 않습니다.
- Hopper `0x100000a58`: `__objc_stubs`의 `0x100004550: BR x16`. selector/dyld 포인터에 대한 추가 해석이 필요합니다.
- Hopper `0x100000a60`, `0x100001740`, `0x1000025ec`: SIMD `MOVI v0.2d, #0` (`0x6f00e400`). `0x100001740`은 CSEL을 통과한 뒤 529개까지 진행하지만 두 SIMD 지점에서 중단합니다.
- Android `0xd80`: JNI 함수 테이블에서 읽은 런타임 `BR x3`. MOVN 실패는 해소했으나 타깃 주소를 추측하지 않습니다.
- Android atomic helper `0xff0`: `LDADDAL` (`0xb8e00020`)과 `LDAXR` (`0x885ffc20`)가 미지원입니다. export wrapper `0xfc8`의 8개 명령이 지원된다는 결과는 이 helper 본문까지 구현했다는 뜻이 아닙니다.

미지원 경로는 `INCOMPLETE`를 유지하며, 미지원을 NOP로 바꾸거나 런타임 포인터·시그니처를 만들어 내지 않습니다.

## 재현

상용 Hopper/Android 원본 파일과 이전 실행 파일은 저장소에 포함하지 않습니다. 이전 실행 파일은 `795da33`을 별도 checkout에서 release 빌드해 준비할 수도 있습니다. 아래 입력 경로를 같은 해시의 파일로 지정합니다. 네이티브 검증에는 Apple Silicon/macOS가 필요합니다.

```sh
cargo test --quiet
cargo clippy --all-targets -- -D warnings
cargo build --release
cargo build --release --example other_reference
mkdir -p validation/other_entries/build
clang -arch arm64 -dynamiclib validation/other_entries/native.s -o validation/other_entries/build/native.dylib
python3 validation/other_entries/verify.py \
  --baseline /path/to/previous/ghidra-hopper-rs \
  --candidate target/release/ghidra-hopper-rs \
  --reference target/release/examples/other_reference \
  --native validation/other_entries/build/native.dylib \
  --hopper '/Applications/Hopper Disassembler.app/Contents/MacOS/hopper' \
  --elf /path/to/original/libdatastore_shared_counter.so
```

검증 스크립트는 전체 로그 대신 JSON을 stdout으로 출력합니다. 생성된 바이너리는 `build/`와 `target/`에서 제외합니다. 설치 경로는 `/Users/gimhyegon/.local/bin/ghidra-hopper-rs`이며 버전 문자열은 `v0.3.0`을 유지합니다.
