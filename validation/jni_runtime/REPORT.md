# Android JNI BR x3 실제 ART 검증

2026-10-31. 기준 커밋은 `1d6dcf383f23406ff33934ab3944b7d41bee5053`, 변경본도 v0.3.0입니다. 실행 파일 해시로 두 빌드를 구분합니다.

## 결과와 범위

원본 Android ELF를 ARM64 Android ART에 실제로 로드·호출하고, `ThrowIoException`의 `0xdc8: BR x3` 직전 레지스터를 관찰했습니다. **관찰한 x3는 JNIEnv 함수 테이블 슬롯 14인 ThrowNew와 일치**했습니다. 앞선 `0xda4: BLR x8`도 테이블 슬롯 6인 FindClass에서 오는 데이터 흐름으로 해석합니다.

같은 ELF·진입점 `0xd80`·예산 128/512/2,048·제공 캡처에서 **출력 명령은 23→23개, 명령 작업량도 23→23개, 종료 코드는 2→0**입니다. 마지막 외부 간접 분기의 식별이 개선된 것이며 ART 함수 본문을 추가로 디컴파일한 결과는 아닙니다.

**캡처를 주지 않은 정적 분석은 23개·종료 코드 2를 유지합니다.** 새 해석은 제공한 오프라인 관찰과 분석 동안 JNIEnv 테이블이 안정적이라는 문맥에 한정됩니다. CLI와 Rust API의 렌더러 모두 이 범위를 표시합니다. 다른 실행의 절대 주소, 원래 MetaTrader 앱 프로세스, 모든 JNI 호출에 이 결과를 자동 적용하지 않습니다.

## 실제 실행 환경

- Android Emulator 36.5.11, ARM64, Android 12 / API 32.
- fingerprint: `google/sdk_gphone64_arm64/emulator64_arm64:12/S2B2.211203.006/8015633:userdebug/dev-keys`.
- 기존 AVD를 `-read-only -no-snapshot-save -no-window`로 실행했습니다.
- NDK 27.1.12297006 / Android API 26 ARM64 compiler, JDK 11, build-tools 35.0.0.
- Android `app_process64`의 실제 JNIEnv를 사용했습니다. 가짜 JNI 테이블이나 macOS JVM 테이블을 쓰지 않았습니다.
- 원본 MetaTrader 앱 대신, 분석용 app_process에 원본 `.so`를 `dlopen`한 검증입니다. 물리 기기에서 실행한 것은 아닙니다.

기본 ART와 `-Xcheck:jni`를 각각 두 개의 독립 프로세스에서 실행했습니다. 총 네 번 모두 테이블 포인터와 x3가 실행마다 달랐으며, 같은 모드의 ART 상대 오프셋은 일치했습니다.

| 캡처 | PID | JNIEnv 테이블 | 관찰 x3 | libart.so 상대 오프셋 |
| --- | ---: | --- | --- | --- |
| default-1 | 7310 | `0x73b4a0e198` | `0x73b479f7c8` | `0x59f7c8` |
| default-2 | 7327 | `0x6f4f20e198` | `0x6f4ef9f7c8` | `0x59f7c8` |
| checkjni-1 | 7344 | `0x76ac80d9a8` | `0x76ac56e130` | `0x56e130` |
| checkjni-2 | 7361 | `0x751020d9a8` | `0x750ff6e130` | `0x56e130` |

정상 모드와 CheckJNI의 대상은 각각 **libart.so+0x59f7c8**, **libart.so+0x56e130**입니다. ELF export 심볼 이름은 해당 주소에서 제공되지 않아 임의의 C++ 심볼명을 붙이지 않았습니다. `JNI.ThrowNew`라는 의미는 실제 JNIEnv 테이블의 타입·슬롯과 실행 결과로 확인했습니다.

## 관찰 방법

[probe.cpp](probe.cpp)는 NDK `jni.h`의 `offsetof(JNINativeInterface, FindClass)==0x30`, `ThrowNew==0x70`를 컴파일 시 검사합니다.

각 프로세스에서 다음 두 호출을 수행합니다.

1. **원본 명령 그대로 호출:** 실제 JNI 함수가 성공적으로 반환하고 pending IOException의 메시지가 지정한 값인지 확인합니다.
2. **분기 레지스터 관찰 호출:** 원본 `BR x3` 워드 `0xd61f0060`을 먼저 확인하고 프로세스 전용 메모리에서 잠시 BRK로 교체합니다. SIGTRAP에서 PC와 x0–x3를 읽고, signal context의 PC를 x3로 설정해 원래 BR의 대상을 실행합니다. 호출 후 원래 워드·메모리 보호·signal handler를 복구하고 같은 예외 결과를 검증합니다.

두 번째 호출의 원래 BR 자체는 BRK 관찰과 signal-context 분기로 대체됩니다. 첫 번째 호출은 그 계측 없이 실행합니다. **네 프로세스 × 두 호출 = 실제 예외 검증 8회**, 분기 레지스터 관찰 4회 모두 통과했습니다. 디스크의 원본 ELF는 변경하지 않았고 기기 복사본 SHA-256도 호스트 원본과 일치했습니다.

관찰한 x0는 실제 JNIEnv, x3는 그 테이블의 ThrowNew 값과 일치했습니다. x1은 유효한 Java 클래스 참조이며 x2는 메시지 포인터입니다. 참조 핸들을 일반 메모리 포인터로 추정하지 않았습니다. 호출 전후 env->functions와 슬롯 6/14가 같은지도 검사했습니다.

JNI 예외는 native stack을 자동으로 unwind하는 noreturn 호출이 아닙니다. 이 검증에서도 ThrowNew가 native return 0과 pending exception을 남겼습니다. 따라서 IR은 `tailcall_runtime_jni("ThrowNew", ...)`와 예외 가능성을 표현하며 `NoReturnCall`로 바꾸지 않습니다.

공식 [JNI 함수 테이블·FindClass·ThrowNew 규격](https://docs.oracle.com/en/java/javase/26/docs/specs/jni/functions.html) 및 [Android JNI 팁의 JNIEnv·CheckJNI·예외 설명](https://developer.android.com/ndk/guides/jni-tips)을 대조했습니다. CheckJNI가 다른 함수 테이블을 사용하는 점도 네 개의 실제 관찰에서 확인했습니다.

## 구현

- `decompile ... --jni-runtime capture.json`을 추가했습니다. 인식하지 못하는 추가 인자·불완전한 옵션도 오류로 처리합니다.
- 캡처와 원본 ELF·기기에서 가져온 ART 이미지의 SHA-256을 대조합니다. ABI/schema, 관찰 x0/x3, 복구된 BR 워드, 테이블 안정성·예외 결과, readable/executable 메모리 매핑, module load bias와 대상의 코드 16바이트를 검사합니다.
- ARM64의 tagged heap pointer는 매핑을 찾을 때만 top-byte-ignore를 적용합니다. 런타임 포인터 자체는 캡처 원형으로 보존합니다.
- CFG의 모든 reaching path에서 JNIEnv→table→slot의 provenance가 일치해야 합니다. 64비트 copy/load와 상수 주소 형성을 추적하고 W 쓰기·다른 슬롯·모호한 join·volatile 호출 clobber·테이블에 대한 쓰기·opaque 호출은 보수적으로 거부합니다. ABI stack 파생 주소와 callee-saved 레지스터를 구분합니다.
- 특정 saved register 번호나 절대 ART 주소를 하드코딩하지 않습니다. 실제 함수에서는 X20이 env를 보존하지만, 회귀 테스트는 다른 saved register로 바뀐 경우도 확인합니다.
- 캡처를 이미 적용한 분석에 다른 문맥을 재사용하지 않고 원본 ELF에서 다시 분석하도록 요구합니다. 분석 후 프로그램 코드가 바뀌어도 오래된 증명을 적용하지 않습니다.
- call의 NZCV/SIMD/exclusive-monitor clobber를 유지합니다. 외부 주소에 대한 참조만 생성하며, ART 주소를 입력 ELF 내부 CFG 노드로 만들지 않습니다.

캡처 JSON은 호출자가 제공한 **오프라인 증거**입니다. 현재 살아 있는 기기 확인이나 서명된 증명서는 아닙니다. 해시·주소·코드 검사는 일관성 검증이며 캡처 발행자를 인증하지 않습니다.

## 동일 조건 비교와 회귀

기준 버전은 추가 CLI 인자를 조용히 무시하는 문제가 있어, 동일한 `--jni-runtime` 인자와 파일을 주어도 적용하지 않습니다. 변경본은 이를 검증·적용합니다. 이 차이를 숨기지 않고 비교 JSON에도 기록했습니다. 주 분석 파일·진입점·명령 예산·제공한 증거 파일은 동일합니다.

| 문맥 | 예산 | 기준 명령/작업/종료 코드 | 변경 명령/작업/종료 코드 | 변경 해석 |
| --- | --- | --- | --- | --- |
| 캡처 없음 | 128 / 512 / 2,048 | 23 / 23 / 2 | 23 / 23 / 2 | 미해결 BR x3 유지 |
| 기본 ART 캡처 2개 | 각각 128 / 512 / 2,048 | 23 / 23 / 2 | 23 / 23 / 0 | FindClass + ThrowNew |
| CheckJNI 캡처 2개 | 각각 128 / 512 / 2,048 | 23 / 23 / 2 | 23 / 23 / 0 | CheckJNI 테이블 대상 |

- 런타임 문맥 비교 **12쌍**: 명령 주소 집합도 완전히 동일합니다.
- 부분 예산 **16건**: 네 캡처 각각 예산 1/9/10/18에서 INCOMPLETE와 원래 예산을 유지합니다.
- 기존 29개 진입점 × 세 예산의 **87쌍**: 캡처 없이 실행한 Hopper와 Android의 명령 수·작업 비용·종료 코드·간접 분기가 기준과 동일합니다.
- 잘못된 문맥·옵션 **12건**: 다른 ELF/ART 해시, x3 불일치, 코드 불일치, 비실행 매핑, 경로 오류, 손상 JSON, 잘못된 진입점 등을 종료 코드 1로 거부합니다.
- 디버그 테스트 **120개**, 릴리스 JNI·정직성 테스트 **12개**, Clippy `--all-targets -- -D warnings`, rustfmt 통과.
- JNI 새 테스트 5개에는 캡처 필드 변조 21종, 변경된 프로그램 코드, 부분 예산, volatile clobber, 좁은 pointer load, 잘못된 슬롯/베이스, 테이블 덮어쓰기, 서로 다른 경로의 join, 재적용과 saved-register 변경을 포함합니다.

상세 수치와 캡처 식별은 [verification.json](verification.json)에 보존했습니다. 이전 라운드 보고서는 당시 결과로 유지합니다.

## 파일 식별

| 대상 | SHA-256 |
| --- | --- |
| 원본 Android ELF | `d3e48717c9aa147e0ab21063ba0e8e0211cabf8bf40b222640829519edbf58e1` |
| pulled libart.so | `2ed780ea89adc6540d0a1ea1a68d563c5da0837eeb9f50e474919dc7f783f721` |
| 기준 설치본 | `094dcdf9d43a2b2395fc5c9e9bd4683ec999c4e7b39ce8f74b193b35151af9df` |
| 변경 release / 설치본 | `f60930bb9ffadf2de9259bb44ebf8e92141a308e7e857e41c52d5a43cb651606` |

원본 ELF 경로는 `/Users/gimhyegon/Desktop/REA_Analysis/outputs/metatrader-4-5-20261029/mt5/lib/arm64-v8a/libdatastore_shared_counter.so`입니다. 기준 실행 파일은 `/Users/gimhyegon/Desktop/REA_Analysis/outputs/ghidra-hopper-rs-jni-runtime-20261031/ghidra-hopper-rs.before-jni-runtime`에 보존했습니다. 원본 ELF·ART 이미지·컴파일된 probe는 GitHub에 재배포하지 않습니다.

## 재현

실행할 ARM64 Android 기기 또는 에뮬레이터를 명시적으로 선택합니다. 수집기는 해당 기기의 전용 임시 디렉터리를 만들고 실행 후 그 디렉터리만 제거합니다. 기존 앱·데이터·시스템 속성은 수정하지 않습니다. API 26 이상과 실행 가능한 `app_process64` 환경을 사용합니다.

```sh
cargo test
cargo clippy --all-targets -- -D warnings
cargo fmt --check
cargo build --release
cargo test --release --test jni_runtime --test honesty
python3 validation/jni_runtime/capture.py \
  --sdk /path/to/Android/sdk \
  --ndk /path/to/Android/sdk/ndk/27.1.12297006 \
  --java-home /path/to/JDK11 \
  --device emulator-5584 \
  --elf /path/to/libdatastore_shared_counter.so
```

수집기의 stdout은 네 개의 프로필 객체를 담은 JSON입니다. 각 객체를 `validation/jni_runtime/default-1.json`, `default-2.json`, `checkjni-1.json`, `checkjni-2.json`에 저장합니다. 해당 실행에서 pull한 ART는 `validation/jni_runtime/build/libart.so`에 있습니다. 기존 관찰을 덮어쓰기 전에 별도로 보관하면 실행별 ASLR 결과를 비교할 수 있습니다.

```sh
target/release/ghidra-hopper-rs decompile \
  /path/to/libdatastore_shared_counter.so ThrowIoException 0xd80 2048 \
  --jni-runtime validation/jni_runtime/default-1.json

python3 validation/jni_runtime/verify.py \
  --baseline /path/to/ghidra-hopper-rs.before-jni-runtime \
  --candidate target/release/ghidra-hopper-rs \
  --elf /path/to/libdatastore_shared_counter.so \
  --hopper "/Applications/Hopper Disassembler.app/Contents/MacOS/hopper"
```

보존된 네 캡처는 이 실행의 주소를 담습니다. 새 기기·새 ART 이미지를 수집하면 새 프로필로 분석해야 합니다. 임의의 JNIEnv 오프셋 해석, 모든 JNI 함수, 다른 VM 또는 ART 본문의 디컴파일은 이번 구현 범위에 포함하지 않습니다.
