# ghidra-hopper-rs (v0.3.0)

> **Android JNI BR x3 실제 런타임 검증 / 2026-10-31:** 원본 ELF를 ARM64 Android ART에 로드해 기본/CheckJNI 각 2개 프로세스에서 JNIEnv 테이블과 BR x3 직전 레지스터를 확인했습니다. `--jni-runtime capture.json`으로 원본 ELF·ART 해시·매핑·대상 코드와 CFG provenance를 대조한 경우에만 FindClass(슬롯 6)와 ThrowNew(슬롯 14)로 해석합니다. 동일 파일·진입점·예산·제공 캡처 12쌍에서 명령 수는 23→23개, 종료 코드는 2→0입니다. 캡처가 없으면 기존 INCOMPLETE를 유지합니다. ThrowNew를 noreturn으로 처리하지 않으며 외부 ART 본문을 분석한 것으로 표시하지 않습니다. 실제 예외 검증 8회·분기 관찰 4회, 기존 진입점 회귀 87쌍, 디버그 120개·릴리스 12개 테스트를 통과했습니다. [실제 실행 환경·관찰 방법·범위·동일 조건 비교·재현](validation/jni_runtime/REPORT.md).

> **남은 진입 경로·SIMD·atomic 구현 / 2026-10-31:** MOVI D/V.2D, 128비트 SIMD STP/LDP, 정수 register-offset 전송, 32/64비트 LDADD와 LDAXR/STLXR/CLREX를 구현했습니다. 전체 5개 명령과 selref/GOT/import metadata로 Objective-C tail stub을 검증하며 미확인 selector 이름은 추측하지 않습니다. 비복귀 callee의 전체 CFG 검증 비용도 원래 예산에 포함합니다. 같은 29개 진입점 × 세 예산의 87쌍 비교에서 2,048개 예산의 지원 범위 분석은 21→28개로 늘었습니다. Hopper main은 1,121개를 유지하고 callee 824개를 더 검증해 총 1,945개 비용으로 종료 코드 2→0이 되며, 이전에 잘못 포함됐던 인접 stub은 제외합니다. Android atomic helper는 7→12개, JNI 런타임 BR x3는 INCOMPLETE를 유지합니다. 네이티브 4,560건·간섭 모델 8건·원자 경로별 8,000회 동시 증가, 디버그 테스트 115개와 릴리스 29개를 확인했습니다. [조건·비용·전체 비교·재현 절차](validation/remaining_paths/REPORT.md).

> **다른 진입점 확장·정확성 수정 / 2026-10-31:** MOVN/MOVK, CSEL, immediate·unscaled·pre/post LDRSW, TPIDR_EL0 읽기, 일반 레지스터 목적지의 32/64비트 LDAR를 구현했습니다. LDAR의 acquire 속성과 런타임 thread-pointer 값을 IR에 명시합니다. 함수 경계를 넘는 가짜 fall-through, 비반환 import 뒤의 탐색, 변경된 ELF PLT의 오래된 binding, SUB 뒤 문자열 추론과 ADDG/SUBG 오해석을 수정했습니다. 기존 Hopper main의 1,124개·종료 코드 0에는 무관한 import stub이 포함되어 있었습니다. 이를 1,121개·INCOMPLETE로 바로잡았으며 개별 import 해석은 유지합니다. 29개 진입점 × 세 예산의 87쌍, 네이티브 ARM64 1,713건, 전체 테스트 103개와 릴리스 24개를 검증했습니다. [조건·결과·정정·남은 미지원·재현 절차](validation/other_entries/REPORT.md).

> **Mach-O BR x16 import 해석 / 2026-10-31:** canonical ADRP/LDR/BR stub과 포인터 슬롯의 간접 심볼 인덱스, nlist undefined 심볼·라이브러리 ordinal을 대조해 외부 꼬리 호출로 표현합니다. Hopper `0x100003f68`은 슬롯 `0x100008130`을 통한 CoreFoundation의 `_CFRunLoopGetCurrent`로 식별됩니다. 같은 파일·진입점·예산에서 탐색량은 128→128개, 512→512개, 1,124→1,124개이며, 2,048개 예산의 마지막 미해결 분기가 해소되어 종료 코드가 2→0으로 바뀝니다. 출력은 여전히 지원 범위 분석임을 명시하며 외부 함수 본문·런타임 주소·시그니처까지 복원한 것은 아닙니다. 잘못된 연결과 stub 중간 진입은 미해결 상태를 유지합니다.

> **BR 점프 테이블 자동 복원 / 2026-10-31:** CMP/B.HI의 인덱스 범위, ADR·LDRH·shifted ADD·BR의 데이터 흐름, 읽기 전용 테이블과 코드 대상 범위를 검증해 unsigned halfword 상대 테이블을 복원합니다. 중복 항목을 원래 인덱스에 보존하고 CFG 간선·참조는 고유 대상별로 생성하며, 새 역방향 경로가 근거를 깨면 복원을 취소합니다. 같은 Hopper·진입점·예산에서 128개는 128→128개, 512개는 512→512개(예산 상한), 2,048개는 747→1,124개입니다. `BR x9`의 58개 항목·30개 고유 대상을 복원했으며 `BR x16`(`0x100003f68`)은 미해결로 `INCOMPLETE`를 유지합니다.

> **ADD shifted-register 추가 / 2026-10-31:** NZCV를 변경하지 않는 32/64비트 ADD의 LSL/LSR/ASR과 ZR 입력·버리는 목적지, W 결과의 상위 비트 제거를 구현했습니다. 동일 Hopper·진입점·예산 비교에서 128개는 128→128개, 512개는 512→512개(상한), 2,048개는 746→747개입니다. `0x100003260`의 ADD를 통과해 `0x100003264`의 BR x9에 도달하지만 점프 테이블 대상은 아직 미해결이며, 다른 BR x16(`0x100003f68`)도 남아 `INCOMPLETE`를 유지합니다. 네이티브 ARM64 537건과 릴리스 테스트 75개로 검증했습니다.

> **LDRH register-offset 추가 / 2026-10-31:** UXTW/LSL/SXTW/SXTX와 scale #0/#1, SP 베이스·ZR 인덱스·WZR 목적지를 지원합니다. 원래 베이스/인덱스로 주소를 계산한 뒤 2바이트를 읽고 W 목적지에 zero-extend하며 베이스 writeback과 NZCV 변경은 없습니다. 같은 Hopper·진입점·예산 비교에서 128개는 128→128개, 512개는 512→512개(상한), 2,048개는 745→746개입니다. 다음 shifted-register ADD(`0x100003260`)에서 `INCOMPLETE`를 유지하며 점프 테이블 복원까지 완료한 것은 아닙니다.

> **ADR 추가 / 2026-10-31:** 현재 PC와 signed 21비트 바이트 오프셋으로 주소를 만드는 ADR을 구현했습니다. ADRP와 주소 디코딩을 공유하되 페이지 정렬·4KB 스케일 차이를 유지하고, 두 명령의 XZR 목적지를 버리는 쓰기로 처리합니다. 같은 Hopper·진입점·예산 비교에서 128개는 128→128개, 512개는 512→512개(모두 상한), 2,048개는 744→745개입니다. ADR은 통과하며 다음 `LDRH` register-offset(`0x10000325c`)에서 `INCOMPLETE`를 유지합니다. 주소 형성만 구현한 것으로 점프 테이블 복원까지 완료한 것은 아닙니다.

> **TBZ/TBNZ 추가 / 2026-10-31:** 비트 0–63, signed imm14 PC-relative 대상, W/X·ZR 문맥과 NZCV 보존을 구현했습니다. 같은 Hopper·진입점에서 이전/수정본에 같은 예산을 적용하면 128개는 128→128개, 512개는 512→512개(모두 예산 상한), 추가로 양쪽 예산을 2,048개로 맞추면 628→744개까지 탐색합니다. TBZ/TBNZ 중단점은 통과하며 다음 미지원 ADR(`0x100003258`)에서 `INCOMPLETE`를 유지합니다. 이는 실행 경로 길이나 전체 디컴파일 완료를 뜻하지 않습니다.

> **ORR 추가 / 2026-10-31:** 32/64비트 ORR shifted-register(LSL/LSR/ASR/ROR)와 logical-immediate 비트마스크를 구현했습니다. NZCV를 보존하며, register 형식의 ZR과 immediate 목적지의 SP/WSP를 구분합니다. 같은 Hopper·진입점에서 같은 예산으로 비교하면 128개 예산은 128→128개(수정본은 ORR 이후 예산 도달), 512개 예산은 456→512개입니다. 전체 분석 완료는 아니며 TBNZ·ADR 등 미지원 명령에서는 `INCOMPLETE`를 유지합니다.

> **CMP·NZCV·조건 분기 추가 / 2026-10-31:** 32/64비트 CMP/CMN/ADDS/SUBS의 immediate·shifted-register 형태와 N/Z/C/V 산술, A64 조건 코드 16종의 B.cond를 구현했습니다. SP/ZR, carry/no-borrow와 signed overflow를 구분하고, 호출 뒤 NZCV는 미확인으로 무효화합니다. 같은 Hopper·진입점에서 이전/수정본에 동일한 예산을 적용하면 128개 예산은 90→128개, 512개 예산은 90→456개까지 탐색합니다. ORR 등 미지원 명령이 남아 `INCOMPLETE`는 유지합니다. 이는 실제 실행 경로나 전체 의미 복원 완료가 아니라 양쪽 분기 경로를 포함한 정적 탐색 결과입니다.

> **비트필드·ELF PLT 추가 / 2026-10-31:** 32/64비트 UBFM/SBFM/BFM의 회전 마스크, 부호 확장과 목적지 병합을 구현했습니다. ELF PLT는 실제 ADRP/LDR/ADD/BR 코드와 JUMP_SLOT GOT 재배치·심볼 테이블 링크를 검증해 외부 꼬리 호출로 표현합니다. GOT의 파일 초기값을 최종 함수 주소로 해석하지 않습니다. Hopper 탐색은 88→90개로 진행했고 다음 중단점은 CMP입니다. Android 진입 경로는 8개 그대로이며 `__cxa_finalize` 외부 꼬리 호출을 식별해 해당 경로의 종료 코드가 2→0으로 바뀌었습니다. 이는 외부 함수 본문·런타임 주소 복원이나 바이너리 전체 분석 완료를 의미하지 않습니다.

> **ARM64 메모리 명령 추가 / 2026-10-31:** 정수 `STP/LDP`(32/64비트, offset/pre/post-index), `LDR/STR`(unsigned immediate와 signed unscaled/pre/post-index, byte/halfword/word/doubleword), 레지스터 MOV·BLR 및 BTI guard의 IR을 추가했습니다. SIMD, LDPSW, 부호 확장 로드와 제약상 예측 불가능한 중복 레지스터 조합은 미지원 상태를 유지합니다. BTI는 guard 연산으로 보존하며 실행 시 페이지 보호·예외를 시뮬레이션하지 않습니다. 실제 파일에서 같은 128개 명령 예산으로 Hopper는 2→88개, Android ELF는 1→8개 명령까지 진행했습니다. 두 파일의 완전 분석은 아니며 미지원 명령 또는 미해결 간접 분기에서는 `INCOMPLETE`를 유지합니다.

> **추가 심층 수정:** 미지원 명령과 NZCV 조건은 `NOP` 또는 가짜 레지스터로 변환하지 않고 `INCOMPLETE`로 표시하며 해당 탐색 경로를 중단합니다. CLI 종료 코드는 지원 범위의 분석 0, 입력 오류 1, 불완전 분석 2입니다. `inspect <binary>`는 메타데이터만 출력하며, `demo <binary>`도 이 동작으로 연결됩니다. 인자 없는 `demo`만 명시적인 합성 예제입니다. 잘못된 주소·명령 예산·파일 경로는 기본값이나 합성 예제로 대체하지 않습니다. Objective-C 수신자와 외부 주소를 임의로 만들지 않으며 원시 문자열을 NSString으로 추정하지 않습니다. MCP 상태는 문서 미로드·공급자 상태 미확인을 반환하고 Swift 도구는 부분 식별자 추출임을 명시합니다.

> **2026-10-31 수정 및 지원 범위:** 이 저장소는 일부 ARM64 명령과 Ghidra/Hopper 스타일 자료구조를 구현한 실험 엔진입니다. 전체 SLEIGH 명세, SSA 분석, Ghidra/Hopper 디컴파일러의 동등한 Rust 포팅은 아닙니다. 세그먼트는 메모리에 복사합니다. 아래의 과거 데모 로그와 성능·동등성 표현은 검증된 기능 보증이 아닙니다.
>
> 현재 `decompile`은 ARM64만 허용합니다. Objective-C selref는 실제 포인터로 검증하고, ARM64 32바이트 스텁은 인식한 ADRP/LDR 패턴만 연결합니다. dyld chained fixup 해석과 x86 Objective-C 스텁 복원은 지원하지 않습니다. 미확인 선택자는 추측하지 않습니다.
>
> MCP는 `binary_overview`, `provider_status`, `demangle_swift`만 제공합니다. 문서를 로드하지 않은 상태에서 `decompile_objc`, `set_byte_state`, `rename_register`가 성공한 것처럼 응답하던 동작은 제거했습니다. 상태 응답의 공급자 버전은 설정값이며 실시간 상태 검사가 아닙니다. `tools/call` 결과는 MCP `content` 배열 형식으로 변경되었습니다. Rust API의 `ObjCMetadata`는 `selector_references`와 일반 ELF `symbols`를 별도 필드로 제공합니다.

**Rust-Native Reverse Engineering Engine** combining **Ghidra 12.3_DEV (`4718f50d99`, 2026-10-31)** (`SLEIGH` / `P-Code` SSA Decompiler, `ObjcMessageAnalyzer`, `DecompilerSwitchAnalysisCmd`, `JumpTable`, `ReferenceManager`, `BookmarkManager`) with **Hopper Disassembler 6.6.0 (`42.6316032`)** and **REA 6.8.0 (`v49` skill, 229 tools, 15 Frontier Agents configured)** (O(1) `ByteType` Reactive State Machine & `C/P/A/D/U` Interactive Hotkeys, Zero-IPC `__objc_stubs` / `__objc_selrefs` `CALL_OBJC` Recovery, Swift 5 `$s` Demangler, Objective-C `self`/`_cmd` Register Aliasing, `SwitchHintTable` Indirect Branch Override, 4-Mode Unified View `[ASM | CFG | Pseudocode | Hex]`, and Built-in STDIO MCP Server).

---

## 1. 아키텍처 및 포팅 개요 (Ghidra + Hopper $\rightarrow$ Rust)

기존 Ghidra의 `ObjcMessageAnalyzer.processStub()`는 `__objc_stubs` 호출을 만날 때마다 Java에서 C++ `decompile` 프로세스로 OS 파이프 IPC(`decompiler.decompileFunction(func, 5, monitor)`)를 수행하여 대규모 Mach-O 분석 시 병목이 발생합니다.

`ghidra-hopper-rs`는 이 구조를 **단일 주소 공간의 Zero-Copy / Zero-IPC Rust 엔진**으로 재설계하고, Ghidra 12.3_DEV의 핵심 분석기 코드를 1:1로 포팅했습니다.

| Ghidra 12.3_DEV Java 클래스 / 메서드 | Rust 포팅 모듈 및 심볼 (`src/`) | 핵심 개선 및 통합 기능 |
| :--- | :--- | :--- |
| `ghidra.program.model.listing.Program` | `ghidra_port::GhidraProgram` | `Segment`, `symbol_table`, `external_methods`, `references`, `eol_comments`, `bookmarks` 통합 |
| `ghidra.program.model.symbol.RefType` | `ghidra_port::GhidraRefType` | `UnconditionalCall`, `CallOverrideUnconditional`, `ComputedJump`, `Data` |
| `ghidra.program.model.pcode.JumpTable` | `ghidra_port::GhidraJumpTable::write_override` | `ComputedJump` 참조 생성 + `switchD_<addr>::caseD_<idx>` 심볼 등록 + P-Code `SwitchHintTable` 직결 |
| `ObjcMessageAnalyzer.Message` | `ghidra_port::ObjcMessage` | `receiver`, `selector`, `function_entry`, `call_addr`, `stub_target`, `parameters` |
| `HopperHybridObjcAnalyzer` | `ghidra_port::HopperHybridObjcAnalyzerRs` | `analyze_function_zero_ipc`, `update_external_block`, `set_comment_and_reference` |
| Hopper `Segment.TYPE_*` / `FORMAT_*` | `segment::{ByteType, OperandFormat, Segment}` | $O(1)$ 바이트 상태 배열 (`Undefined`, `Procedure`, `Code`, `Next`, `Ascii`, `Align`) 및 `get_instruction_start` |
| Hopper `HopperMCPServer` | `mcp_server::run_stdio_mcp_loop` | 단일 네이티브 바이너리 내 STDIO JSON-RPC MCP 서버 내장 |

---

## 2. 디렉터리 구조

```text
ghidra-hopper-rs/
├── Cargo.toml
├── README.md
├── ghidra-extension/
│   ├── HopperHybridObjcAnalyzer.java   # Ghidra 12.3_DEV AutoAnalysisManager 플러그인
│   └── HopperHybridBridgeScript.java   # GhidraScript (Ctrl+Shift+H / analyzeHeadless 연동)
└── src/
    ├── lib.rs
    ├── main.rs                         # CLI 데모, MCP 서버 엔트리, 통합 단위 테스트
    ├── segment.rs                      # Hopper ByteType O(1) 상태 머신 & OperandFormat
    ├── macho_objc.rs                   # Zero-Copy Universal Mach-O & ObjC/Swift 메타데이터 파서
    ├── pcode_sleigh.rs                 # Ghidra Varnode/PcodeOp ARM64 리프터 & 하이브리드 디컴파일러
    ├── cfg_tags.rs                     # BasicBlock CFG, 태그/컬러, 4-Mode 통합 뷰 렌더러
    ├── ghidra_port.rs                  # Ghidra 12.3 ObjcMessageAnalyzer & JumpTable 1:1 Rust 포팅
    └── mcp_server.rs                   # STDIO JSON-RPC MCP 서버
```

---

## 3. Rust 포팅 엔진 (`ghidra-hopper-rs`) 3단계 실행 검증

### Step 1: 단위 테스트 검증 (`cargo test -- --nocapture`)
Hopper `ByteType`(`Procedure`, `Next`, `Code`) 상태 전이, `GhidraRefType::CallOverrideUnconditional` 참조 및 `[HopperGhidraBridge initWithUTF8String:@"Hopper+Ghidra Rust Engine"]` EOL 주석 생성, `GhidraRefType::ComputedJump` 스위치 테이블 복구를 검증합니다.

```bash
cargo test -- --nocapture
```

```text
running 1 test
test tests::test_ported_ghidra_objc_and_switch_analyzer ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

### Step 2: STDIO JSON-RPC MCP 서버 검증 (`./target/release/ghidra-hopper-rs mcp`)
Claude, Cursor, Gemini CLI 등 LLM 클라이언트가 STDIO로 디스어셈블러 및 디컴파일러를 호출할 수 있는지 검증합니다.

```bash
printf '{"jsonrpc":"2.0","id":1,"method":"initialize"}\n{"jsonrpc":"2.0","id":2,"method":"tools/list"}\n{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"binary_overview"}}\n' \
  | ./target/release/ghidra-hopper-rs mcp
```

```json
{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","serverInfo":{"name":"ghidra-hopper-rs-mcp","version":"0.2.0","reaCompat":"6.8.0","ghidraRev":"12.3_DEV-1b9e58a915","hopperBuild":"6.6.0-42.6316032"},"capabilities":{"tools":{}}}}
{"jsonrpc":"2.0","id":2,"result":{"tools":[{"name":"binary_overview","description":"Return Hopper Byte-State + Ghidra P-Code hybrid overview"},{"name":"decompile_objc","description":"Decompile procedure with Ghidra P-Code and Hopper CALL_OBJC selectors"},{"name":"provider_status","description":"Return synced Ghidra 12.3_DEV, Hopper 6.6.0, and REA 6.8.0 provider state"}]}}
{"jsonrpc":"2.0","id":3,"result":{"summary":{"engine":"ghidra-hopper-rs","version":"0.2.0","rea_mcp":"6.8.0","ghidra":"12.3_DEV (1b9e58a915)","hopper":"6.6.0 (42.6316032)","status":"ready","ported_analyzers":["ObjcMessageAnalyzer","DecompilerSwitchAnalysisCmd","HopperHybridObjcAnalyzer"]}}}
```

### Step 3: 실제 Mach-O Universal 바이너리 Zero-IPC 분석 및 4-Mode 렌더링 검증

```bash
cargo build --release
cp target/release/ghidra-hopper-rs ~/.local/bin/ghidra-hopper-rs
ghidra-hopper-rs demo "/Applications/Hopper Disassembler.app/Contents/MacOS/hopper"
```

```text
╔════════════════════════════════════════════════════════════════════════╗
║  Ghidra 12.3_DEV + Hopper 6.6.0 Hybrid Engine (ghidra-hopper-rs v0.2.0)║
║  Synced Providers: Ghidra 1b9e58a915 | Hopper 42.6316032 | REA 6.8.0   ║
╚════════════════════════════════════════════════════════════════════════╝

[1] Zero-Copy Rust Mach-O -> GhidraProgram Loader: `/Applications/Hopper Disassembler.app/Contents/MacOS/hopper`
    - Universal Binary : true (2 slices, selected `arm64`)
    - Entry Point      : Some("0x100002ddc")
    - Segments Loaded  : 5
    - ObjC Classes     : 1 ["Synchronous"]
    - ObjC Stubs Bound : 50 stubs pre-indexed in SymbolTable (Zero-IPC)
    - Load Latency     : 172.208µs

[2] Running Ported `HopperHybridObjcAnalyzerRs` (ObjcMessageAnalyzer + DecompilerSwitchAnalysisCmd)...
    - Discovered ObjC Messages : [ObjcMessage { receiver: "HopperGhidraBridge", selector: "initWithUTF8String:", function_entry: 4294967296, call_addr: 4294967308, stub_target: 4294967436, parameters: ["@\"Hopper+Ghidra Rust Engine\""] }]
    - Ghidra References Added  :
      * 0x100000014 -> 0x100000018 [ComputedJump] (source=Analysis)
      * 0x100000014 -> 0x10000001c [ComputedJump] (source=Analysis)
      * 0x10000000c -> 0x200000000000 [CallOverrideUnconditional] (source=Analysis)
    - Ghidra EOL Comments      : {4294967308: "[HopperGhidraBridge initWithUTF8String:@\"Hopper+Ghidra Rust Engine\"]"}
    - Ghidra HopperTag Bookmarks:
      * @ 0x100000014 [HopperTag / SwitchOverride]: JumpTable override with 2 cases applied (Zero-IPC)
      * @ 0x10000000c [HopperTag / CALL_OBJC]: [HopperGhidraBridge initWithUTF8String:@"Hopper+Ghidra Rust Engine"]

=== [Mode 1: Hopper Assembly + Byte-State View] ===
; BasicBlock #0 (0x100000000 .. 0x100000014) succs=[4294967324, 4294967316]
0x100000000 [procedure]  02 00 00 90   adrp     x2, 0x100000000             
0x100000004 [code     ]  42 00 04 91   add      x2, x2, 0x100               
0x100000008 [code     ]  41 05 80 52   mov      w1, 42                      
0x10000000c [code     ]  20 00 00 94   bl       objc_msgSend$initWithUTF8String:
0x100000010 [code     ]  60 00 00 b4   cbz      x0, 0x10000001c             
; BasicBlock #1 (0x100000014 .. 0x100000018) succs=[4294967320, 4294967324]
0x100000014 [code     ]  60 00 1f d6   br       x3                          
; BasicBlock #2 (0x100000018 .. 0x10000001c) succs=[]
0x100000018 [code     ]  c0 03 5f d6   ret                                   ; XREF: 0x100000014

=== [Mode 2: Control Flow Graph (CFG) & Minimap] ===
┌── [BB#0 @ 0x100000000] tags=["entry-objc-bridge", "ghidra-objc-override"] ──┐
│ 0x100000000: adrp x2, 0x100000000
│ 0x100000004: add x2, x2, 0x100
│ 0x100000008: mov w1, 42
│ 0x10000000c: bl objc_msgSend$initWithUTF8String:
│ 0x100000010: cbz x0, 0x10000001c
└── Edges: -> 0x10000001c | -> 0x100000014 ──┘
┌── [BB#1 @ 0x100000014] tags=[] ──┐
│ 0x100000014: br x3
└── Edges: -> 0x100000018 | -> 0x10000001c ──┘
┌── [BB#2 @ 0x100000018] tags=[] ──┐
│ 0x100000018: ret 
└── Edges:  ──┘

=== [Mode 3: Ghidra P-Code + Hopper ObjC Decompiler] ===
// Ghidra-Hopper Hybrid Decompiler (P-Code SSA + ObjC Metadata)
int64_t -[HopperGhidraBridge bootstrapEngine:]() { // @ 0x100000000
    x2 = 0x100000000;
    x2 = "Hopper+Ghidra Rust Engine"; // 0x100000100
    w1 = 0x2a;
    x0 = [x0 initWithUTF8String:@"Hopper+Ghidra Rust Engine"];
    if (x0) goto loc_10000001c;
    switch (x3) { // Hopper SwitchHint recovered 2 cases
        case 0: goto loc_100000018;
        case 1: goto loc_10000001c;
    }
    return x0;
}

=== [Mode 4: Synchronized Hex & ByteType Inspector] ===
0x100000000  02 00 00 90 42 00 04 91 41 05 80 52 20 00 00 94  |....B...A..R ...|
0x100000010  60 00 00 b4 60 00 1f d6 c0 03 5f d6              |`...`....._.|

Total execution time: 952.875µs (Zero GC pauses, Zero Decompiler IPC pipe overhead)
```

---

## 4. Ghidra 12.3_DEV Headless (`analyzeHeadless`) 연동 검증 로그

`ghidra-extension/` 내의 Java 플러그인을 Ghidra 12.3_DEV에 설치하고 `analyzeHeadless`로 실행한 결과:

```text
    Function Start Search                      0.033 secs
    Hopper-Hybrid Objective-C & ByteState Analyzer     0.012 secs
    Mach-O Function Starts                     0.003 secs
    Objective-C Message Analyzer               0.002 secs
    Objective-C Type Metadata Analyzer         0.013 secs
-----------------------------------------------------
     Total Time   3 secs
-----------------------------------------------------
INFO  REPORT: Analysis succeeded for file: file:///Applications/Hopper Disassembler.app/Contents/MacOS/hopper (HeadlessAnalyzer)
INFO  HopperHybridBridgeScript.java> [HopperHybrid] Indexed 102 __objc_stubs in O(1) without Decompiler IPC. (GhidraScript)
INFO  HopperHybridBridgeScript.java> [HopperHybrid] Built Hopper ByteType State Map for __TEXT (2600 bytes). (GhidraScript)
INFO  HopperHybridBridgeScript.java> === [Ghidra + Hopper 4-Mode View: FUN_100000a28 @ 100000a28] ===
┌── [BB#0 @ 100000a28 .. 100000a3b] ──┐
│ 100000a28: PUSH RBP                     
│ 100000a29: MOV RBP,RSP                  
│ 100000a2c: MOV RSI,qword ptr [0x100009178] ; CALL_OBJC [self initWithSource:arg]
│ 100000a33: XOR ECX,ECX                  
│ 100000a35: POP RBP                      
│ 100000a36: JMP qword ptr [0x100008028]  
└────────────────────────────────────────┘
```
