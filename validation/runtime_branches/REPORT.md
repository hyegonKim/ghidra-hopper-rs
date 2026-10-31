# 남은 런타임 간접 분기 네 곳의 실제 실행 검증

2026-10-31. 기준 커밋: `fbfb6e36e64db1d1d77cb32ca343d655112c0938`.

**네 곳 모두 실제 런타임 값을 확인했다. 세 곳은 제공한 실행 문맥 안에서 호출 대상을 해석했다. 나머지 PLT resolver는 x17=0으로 실제 SIGSEGV가 발생했으므로 호출 가능한 대상으로 만들지 않고 INCOMPLETE를 유지한다.** 이는 네 곳이 모두 정상 실행된다는 결과가 아니다.

## 실행 환경과 관찰 범위

기존 ARM64 Android 12 / API 32 AVD를 `-read-only -no-snapshot-save -no-window`로 실행했다. fingerprint는 `google/sdk_gphone64_arm64/emulator64_arm64:12/S2B2.211203.006/8015633:userdebug/dev-keys`다. REA의 기기 식별 결과도 Android 12·SDK 32·arm64-v8a와 일치했다. 수집 완료 후 이번 작업이 시작한 emulator-5584를 종료했다. 기존 앱·AVD 원본 데이터·시스템 속성은 변경하지 않았다.

NDK 27.1.12297006, JDK 11, build-tools 35.0.0으로 [probe.cpp](probe.cpp)와 [RuntimeBranchesProbe.java](RuntimeBranchesProbe.java)를 빌드했다. 원본 counter 및 image_processing ELF를 전용 `app_process64`에 로드했다. **원래 MetaTrader 앱 프로세스나 물리 기기의 관찰이 아니라 통제된 재실행이다.** 기본 ART 두 프로세스와 `-Xcheck:jni` 두 프로세스, 총 PID 6908/6946/6978/7010에서 각각 네 종류의 새 캡처를 얻었다.

원본 파일과 기기 복사본의 SHA-256이 같음을 검사했다. 먼저 원본 명령 그대로 실행하고, 두 번째 호출에서는 BR 워드를 프로세스 전용 BRK로 잠시 바꾸었다. SIGTRAP에서 분기 직전 레지스터를 기록하고 signal context의 PC를 해당 레지스터 값으로 설정해 대상을 실행했다. 두 번째 호출은 BR 자체를 signal-context 전송으로 대체한 계측이다. 원래 명령·메모리 보호·signal handler를 복구했다. 디스크의 ELF는 수정하지 않았다.

## 실제 값과 실행 결과

| ELF / 진입점 / 분기 | 실제 대상 | 검증 결과 |
| --- | --- | --- |
| counter / `0xd80` / `0xdc8: BR x3` | JNIEnv 슬롯 14 ThrowNew | 기본 ART `libart.so+0x59f7c8`, CheckJNI `+0x56e130`; 원본·계측 호출 모두 native return 0 및 IOException 메시지 확인 |
| image_processing / `0x719c` / `0x71dc: BR x3` | JNIEnv 슬롯 229 NewDirectByteBuffer | 기본 ART `libart.so+0x422f7c`, CheckJNI `+0x5895cc`; 앞선 BLR x8은 슬롯 230 GetDirectBufferAddress |
| counter / `0xd50` / `0xd5c: BR x16` | 이번 재실행에서 등록한 콜백 | 각 프로세스의 `librea_runtime_branches.so+0x46b8`; X0→X16과 실제 callback 실행 일치 |
| counter / `0x10c0` / `0x10d0: BR x17` | **0, 호출 불가능** | GOT `load_bias+0x53b0`의 값이 전후 모두 0. 원본과 계측 호출에서 각각 SIGSEGV, PC=0, fault address=0 |

JNI 슬롯은 NDK `jni.h`의 `offsetof`를 컴파일 시 검사했으며 공식 [JNI 함수 테이블 규격](https://docs.oracle.com/en/java/javase/26/docs/specs/jni/functions.html)과 대조했다. ART·CheckJNI의 서로 다른 대상 오프셋과 프로세스별 ASLR 주소를 원시 캡처에 보존했다. JNI 참조 핸들을 일반 메모리 주소로 추정하지 않았다.

NewDirectByteBuffer 검증에서는 128바이트의 유효한 native 저장소를 원본 함수에 direct buffer로 넘겼다. offset=7, length=31로 만든 결과의 주소가 `source+7`, capacity가 31이며 내용도 같은지 원본·계측 양쪽에서 검사했다. 관찰 X0는 JNIEnv, X1은 source+7, X2는 31, X3는 실제 슬롯 229 값과 같았다. 슬롯 229/230과 env->functions는 호출 전후 같았다.

`0xd50`은 임의 런타임 linker stub이 아니라 **X0로 받은 함수 포인터를 X16으로 옮기는 callback wrapper**였다. 원본 `0xd64`의 atexit 등록 경로에 분석용 콜백을 등록하고 실제 `__cxa_finalize`로 실행했다. 단순히 외부 주소를 힌트로 넣은 것이 아니다. null 인자를 직접 호출하면 callback 없이 RET로 돌아오는 guard도 확인했다. 다만 이 콜백은 **이번 probe가 제공한 입력**이다. 원래 앱이 등록할 모든 callback의 대상이라고 일반화하지 않는다. 해석은 캡처의 entry X0에 조건부이며 signature는 unknown으로 유지한다.

PLT header를 직접 실행하는 검증은 private process에서 SIGSEGV를 관찰한 뒤 siglongjmp로 복귀했다. 해당 0은 다른 함수 이름이나 linker 주소로 치환하지 않았다. [Bionic linker의 eager binding 처리](https://android.googlesource.com/platform/bionic/+/master/linker/linker.cpp)는 보조 근거이며, 이 결과의 직접 근거는 **이 기기에서 읽은 GOT와 실제 두 번의 fault**다. 다른 loader 환경의 resolver까지 0이라고 단정하지 않는다.

실제 실행 횟수: ThrowNew 예외 확인 8회, buffer 주소·크기·내용 확인 8회, 등록 callback 실행 8회 및 null guard 4회, resolver fault 8회. BR 직전 관찰은 총 16회이며 [16개 새 캡처](verification.json)의 각 프로필 해시·PID·대상 값을 보존했다.

## 구현과 잘못된 증거 거부

- `--jni-runtime`의 기존 schema 1을 유지하고 schema 2에 NewDirectByteBuffer/GetDirectBufferAddress의 정확한 슬롯 쌍을 추가했다. 잘못된 슬롯·buffer 주소/크기·실행 결과·ART 코드/해시·매핑은 거부한다. 기본/CheckJNI 이름을 하드코딩한 주소로 대체하지 않는다.
- `--branch-runtime capture.json`과 Rust `RuntimeBranchSnapshot`을 추가했다. 원본 ELF·provider SHA-256, load bias, 원본/복구 BR 워드, 관찰 레지스터, executable/readable 매핑 및 대상의 16바이트 코드를 확인한다. callback은 등록·finalize·원본/계측 실행 증거를, null resolver는 안정된 GOT와 원본/계측 fault 증거를 요구한다.
- 원본 CFG의 모든 reaching path에서 값의 출처를 추적한다. entry 인자와 캡처된 메모리는 다른 종류로 구분해, 같은 숫자의 상수만으로 runtime proof를 만들지 않는다. W 쓰기, 다른 메모리 슬롯, 모호한 합류, opaque call, 비-stack 메모리 쓰기는 보수적으로 증명을 폐기한다.
- 이미 적용한 분석, 다른 진입점, 바뀐 live code에 오래된 문맥을 재사용하지 않는다. 원래 명령 예산 밖의 코드를 새로 디코딩하지 않으며 외부 ART/callback 본문을 입력 ELF의 CFG로 가져오지 않는다.
- `RuntimeTailCall`은 외부 callback을 표현하고 native return 가능성을 유지한다. `RuntimeInvalidBranch`는 실제 fault를 표시하며 **완료나 noreturn proof로 승격하지 않는다**. CLI뿐 아니라 Rust API 렌더러도 문맥·한계를 표시한다. 새 public Pcode variant를 exhaustive match하는 외부 코드는 갱신이 필요하다.

JSON은 호출자가 제공한 오프라인 증거다. 해시·코드·매핑 검사는 일관성 확인이며 현재 살아 있는 기기나 캡처 발행자를 인증하는 서명은 아니다.

## 동일 조건 비교

직전과 같은 입력 7개·172개 진입점, 예산 128/512/2,048의 **516쌍**을 캡처 없이 비교했다. 모든 명령 수·작업량·상태·중단점이 같다. 입력 해시도 실행 전후 같았다.

| 예산 | 지원 범위 내 종료, 이전→수정 | 출력 명령 합, 이전→수정 |
| --- | ---: | ---: |
| 128 | 146→146 | 5,067→5,067 |
| 512 | 163→163 | 7,707→7,707 |
| 2,048 | 168→168 | 8,737→8,737 |

새 캡처 16개 각각에 같은 파일·진입점·예산·옵션·프로필 경로를 양쪽 버전에 주어 **48쌍**을 별도로 비교했다. 아래 각 행은 네 프로세스 × 세 예산의 12쌍이다.

| 문맥 | 캡처 없는 기준: 명령/작업/종료 | **같은 캡처를 준 이전 버전** | 캡처를 준 수정본: 명령/작업/종료 |
| --- | --- | --- | --- |
| ThrowNew `0xd80` | 23/23/2 | 23/23/0, 기존 기능 | 23/23/0 |
| NewDirectByteBuffer `0x719c` | 17/17/2 | schema 2 미지원, **종료 1** | 17/17/0 |
| 등록 callback `0xd50` | 5/5/2 | 새 옵션 미지원, **종료 1** | 5/5/0, entry X0 문맥에 한정 |
| null PLT `0x10c0` | 5/5/2 | 새 옵션 미지원, **종료 1** | 5/5/**2**, fault 명시 |

이전 버전이 새 캡처를 처리하지 못한 36쌍에는 명령 수를 0 또는 정상 분석으로 기입하지 않았다. `same_context_before_decoded=null`과 실제 오류를 기록하고, 캡처 없는 기준 결과를 별도 보존했다. 이미 지원한 ThrowNew는 새 수집으로 재검증했으며 새 구현의 증가분으로 계산하지 않았다.

수정본은 네 진입점 모두 원래 정적 분석과 **명령 주소 집합·작업량이 동일**하다. 개선은 외부 대상을 식별하고 오류를 정확히 구분한 것이며, 추가 실행 경로나 외부 함수 본문을 디컴파일한 결과가 아니다. 캡처 없이 네 미해결 분기를 자동 해석하지 않는다.

추가 검증: 부분 예산 문맥 24건에서 INCOMPLETE와 예산 상한 유지, 기존 JNI 캡처 회귀 12쌍 유지. 디버그 전체 **154개**, 관련 릴리스 **20개** 테스트 통과. 새 테스트는 profile 필드 변조, wrong entry·changed live code·재적용, W로 좁아진 포인터, 잘못된 메모리 출처·쓰기에 의한 proof 폐기, null fault를 정상 완료로 처리하지 않는 경우를 포함한다. Clippy `--all-targets -- -D warnings`, rustfmt, `git diff --check`도 통과했다. Hopper selector 51개·ObjC stub 50개를 유지했다.

## 식별 및 재현

- 기준 release SHA-256: `493cc79368e6fad68156ecaaa0af0b2eb8e3b71100be31504ce9cadd02f97f8e`.
- 수정 release·설치본 SHA-256: `74fe10865c18fb846e04ce443a15bd0ff81367cb5c42635e589c4528ed8d0315`.
- ART SHA-256: `2ed780ea89adc6540d0a1ea1a68d563c5da0837eeb9f50e474919dc7f783f721`.
- 분석용 callback provider SHA-256: `689176c0a7489ec2a84499afd9888661ebd12908e374ae1f9739eadf35d3221c`.

원본 ELF 경로와 해시는 [기존 입력 식별 표](../wide/REPORT.md#빌드-및-입력-식별) 및 [verification.json](verification.json)과 같다. 기준 보존본은 `/Users/gimhyegon/Desktop/REA_Analysis/outputs/ghidra-hopper-rs-runtime-four-20261031/ghidra-hopper-rs.before-runtime-four`다. 설치본 `/Users/gimhyegon/.local/bin/ghidra-hopper-rs`를 같은 release 해시로 갱신하고 네 문맥의 명령 수·종료 상태를 재확인했다.

상용 ELF·pulled ART·생성 provider는 GitHub에 재배포하지 않는다. 재현 시 해당 이미지와 ARM64 Android 실행 환경이 필요하다. 수집기는 명시한 기기의 새 임시 디렉터리만 사용·제거한다. 새 수집은 새 ASLR 주소/해시를 가진 새 프로필로 저장하며 보존된 관찰을 덮어쓰지 않는다.

```sh
cargo test
cargo clippy --all-targets -- -D warnings
cargo fmt --check
cargo build --release
cargo test --release --test runtime_branch --test jni_runtime --test honesty
python3 validation/runtime_branches/capture.py \
  --sdk /path/to/Android/sdk --ndk /path/to/ndk/27.1.12297006 \
  --java-home /path/to/JDK11 --elf-dir /path/to/mt5/lib/arm64-v8a \
  --device emulator-5584
```

수집기의 stdout은 16개 프로필을 담은 JSON이다. 각 객체를 이름별 새 `.json` 파일로 저장한다. 해당 수집의 ART/provider/original ELF가 프로필의 `runtime_image` 상대 경로에 있어야 하며 해시가 다르면 분석을 거부한다. 이전 캡처의 runtime 이미지를 새 빌드로 덮어쓰지 않는다.

```sh
target/release/ghidra-hopper-rs decompile /path/to/libimage_processing_util_jni.so buffer 0x719c 2048 \
  --jni-runtime validation/runtime_branches/default-1-buffer.json
target/release/ghidra-hopper-rs decompile /path/to/libdatastore_shared_counter.so callback 0xd50 2048 \
  --branch-runtime validation/runtime_branches/default-1-callback.json
target/release/ghidra-hopper-rs decompile /path/to/libdatastore_shared_counter.so resolver 0x10c0 2048 \
  --branch-runtime validation/runtime_branches/default-1-resolver.json
python3 validation/runtime_branches/verify.py \
  --baseline /path/to/ghidra-hopper-rs.before-runtime-four \
  --candidate target/release/ghidra-hopper-rs \
  --hopper "/Applications/Hopper Disassembler.app/Contents/MacOS/hopper" \
  --elf-dir /path/to/mt5/lib/arm64-v8a
```

verify.py의 JSON stdout을 저장한 결과가 verification.json이다. 과거 보고서와 캡처는 그대로 보존했다.
