# AI Workflow

## 시작

1. `docs/README.md`, `HANDOFF.md`, `PROJECT_BRIEF.md`, `SESSION.md`,
   `TODO.md`를 읽는다.
2. Git 상태와 최근 커밋을 확인한다.
3. 관련 코드와 기술/결정 문서를 읽는다.
4. DexManager가 실행 중이면 빌드 파일 잠금 여부를 확인한다.

## 수정 원칙

- 기존 기능, 사용자 설정, 미커밋 변경을 보존한다.
- 요청 범위의 최소 변경을 한다.
- .NET Framework 4.6.2와 64비트 Windows 7 호환성을 유지한다.
- ADB는 `AdbService`와 선택한 절대 경로로 실행한다.
- 관리형 파일 전송의 `DXMAdbProxy.exe`는 DeX·단일창 Scrcpy 프로세스에만
  지정한다. DX Manager 자체 ADB, 무선, wake-up과 화면 상태 경로에는
  사용하지 않으며 세션 대상 폴더의 파일·폴더 push 이외의 명령을 가로채지
  않는다.
- Scrcpy 시작 직렬화 규칙을 지킨다.
- display ID가 모호하면 추측하지 않는다.
- 런타임 설정, 로그와 캡처를 Git에 추가하거나 덮어쓰지 않는다.
- v2 다중 기기 브랜치에서는 물리 identity별 서비스 묶음을 유지한다. 기기 탭을
  바꿔도 비선택 세션을 중지하지 않고, 전역 단축키·키보드 후킹만 선택 탭으로
  이동한다. 종료·분리·전송 취소는 모든 기기를 순회하되 각 serial 범위를 지킨다.

## 검증

```powershell
& 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe' `
  'E:\vs\dex system\DexManager.sln' /t:Build /p:Configuration=Release `
  '/p:TargetFrameworkRootPath=E:\vs\dex system\.build-tools\net462\build' /m
```

변경에 따라 설정 보존, USB/무선 target serial, DeX/단일창 동시 실행,
화면 OFF/stay-awake 복구를 확인한다. 다중 기기 변경은 기기 탭별 독립 실행,
같은 기기의 USB/무선 전환, 비선택 세션 유지, 기기별 분리와 전체 종료를 확인한다.
파일 전송 변경은 Windows 7 SP1~11에서 한글·Unicode 단일/복수 파일과 폴더 전체,
빈 폴더, 사용자 대상 경로, 이름 충돌, 취소, 독립 상태창, Scrcpy 창 종료와
설정 OFF 뒤 새 창의 순정 동작을 확인한다. 상태창은 퍼센트·남은 시간을
표시하지 않아야 한다. ADB 버전은 공통 `1.0.41` 줄이 아니라 실제
`Version ...` 값이 표시되는지 확인한다.
실기 확인을 못 했으면 명시한다.

공개용 포터블 폴더와 ZIP은 저장소 루트에서 다음 명령으로 만든다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Package-Release.ps1
```

macOS 공개 후보는 사용자가 빌드하지 않아도 되도록 아키텍처별 self-contained
ZIP을 미리 만든다.

```bash
scripts/Package-Mac-Release.sh --rid osx-arm64
scripts/Package-Mac-Release.sh --rid osx-x64
```

macOS 스크립트는 현재 저장소의 x86 전용 개발 도구를 그대로 복사하지 않는다.
DX Manager와 `DXMAdbProxy`를 대상 RID로 publish하고, SHA-256을 고정한 공식
scrcpy 4.1 macOS 정적 아카이브를 아키텍처별로 넣는다. ZIP을 다시 풀어 실행
권한, Mach-O 아키텍처, 외부 Homebrew·사용자 경로 의존성, 버전, 필수 문서와
사용자 데이터·디버그 파일 제외를 확인한다. 파일 권한·순서·시각은
`SOURCE_DATE_EPOCH` 또는 현재 Git 커밋 시각으로 정규화한다. GitHub Actions
workflow는 `macos-15`와 `macos-15-intel`에서 두 패키지를 각각 빌드·테스트해
PR artifact로 보관한다. `v*` 버전 태그에서는 두 ZIP과 체크섬을 다시 검증한 뒤
Release 초안을 만들고, 유지관리자가 초안을 확인한 뒤 공개한다.

### Unreleased macOS candidate verification

`--include-app` adds an optional `DX Manager.app` to the portable ZIP; the
candidate CI enables this option. Verify
the native launcher, inner tools, bundle signature, checksum, and app data paths
outside the bundle. Keep published release artifacts unchanged. A local
ad hoc signature is not proof of Developer ID/notarization or browser-download
Gatekeeper approval.

Run settings isolation/save-failure tests. Verify that TUI `O` only displays
shortcut help and does not launch a screen-control helper. For phone tests,
focus the intended scrcpy window and check its native left `Option+O` and
`Option+Shift+O` shortcuts, including an on/off sequence and normal cleanup.
Capture the target model/firmware and the original overlay, stay-awake, and
timeout settings, then verify restoration. Do not turn a single-device
baseline into a cross-model claim or reuse previous preview checks for a new
candidate revision.
The candidate package smoke checks use `--version`, `--help`, app `--verify`,
and a tampered-copy rejection check; they do not start the interactive TUI.
Any separate TUI test must use an explicitly isolated or approved device
environment. Non-device checks do not validate actual DeX or first-launch
security approval.

### 한국어

`--include-app`은 포터블 ZIP에 선택형 `DX Manager.app`을 추가하며 후보 CI에서도
이 옵션을 사용한다. 네이티브
실행기·내부 도구·번들 서명·체크섬과 번들 밖 데이터 경로를 확인한다. 공개된
릴리스 파일은 보존한다. 로컬 ad hoc 서명은 Developer ID·공증이나 브라우저
다운로드의 Gatekeeper 승인을 검증한 결과가 아니다.

설정 분리·저장 실패를 테스트하고 TUI `O`가 단축키 안내만 표시하며 화면 제어
helper를 실행하지 않는지 확인한다. 기기 실기는 대상 scrcpy 창에 포커스를 두고
왼쪽 `Option+O`·`Option+Shift+O`의 켜기·끄기 순서와 정상 종료를 확인한다.
모델·펌웨어와 원래 overlay·stay-awake·timeout 값을 기록하고 종료 뒤 복원을
재확인한다. 한 기기 결과를 다른 모델로 확대하거나 이전 preview의 검증을 새
후보에 그대로 적용하지 않는다. 후보 패키지의 smoke
검증은 `--version`·`--help`·앱 `--verify`와 변조 복사본 거부를 사용하며 대화형
TUI를 시작하지 않는다. 별도 TUI 검증은 명시적으로 격리했거나 승인받은 기기
환경에서 실행한다. 기기를 제어하지 않는 확인과 실제 DeX·최초 보안 승인을
구분한다.

시스템에 .NET Framework 4.6.2 Developer Pack이 없으면 참조 어셈블리 루트를
`-TargetFrameworkRootPath`로 지정하거나 현재 셸의
`DXM_TARGET_FRAMEWORK_ROOT` 환경 변수에 설정한다.

개발 산출물은 `DexManager\bin\Release`, 사용자 배포 산출물은
`dist\DX Manager`와 버전이 포함된 x64 ZIP으로 구분한다.
메이님에게 전달하거나 GitHub에 게시할 최종 릴리스 산출물은 항상
`E:\vs\dex system\dist`에서 생성·확인한다. C 드라이브의 Codex 작업 폴더에서
만든 `bin\Release`와 `dist`는 빌드·실기 검증용으로만 사용하며 정식 릴리스본으로
안내하지 않는다.
스크립트는 DX Manager 실행 여부를 확인하고 번들 Release ADB 서버를 정리한
뒤 Debug/Release의 로그와 스크린샷 테스트 파일을 비운다.
v2.0.1 패키지는 Scrcpy 4.1 런타임,
`tools\adb-proxy\DXMAdbProxy.exe`와 서명이 검증된
`tools\companion\DX-Companion.apk`를 반드시 포함해야 한다.

Android 정리 앱은 다음 명령으로 단위 테스트, lint와 서명 Release 빌드를
함께 실행한다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\Build-AndroidCleanup.ps1
```

Android 앱은 문서화된 복구 설정 이외의 설정이나 임의 shell 기능을 추가하지
않고, 네트워크는 인증된 로컬 전송·guardian 세션으로 제한한다.
`signing.properties`, keystore, 비밀번호와 Android
빌드 산출물은 Git에 넣지 않는다. Release keystore는 Git 외부에 안전하게
백업하고 공개 인증서 지문은 `DXDisplayCleanup/SIGNING.md`와 대조한다.

## Git과 문서

- diff를 확인하고 한 커밋에 한 목적만 담는다.
- 생성물과 사용자 데이터를 커밋하지 않는다.
- 빌드·커밋·배포 전에 `bin\Debug`와 `bin\Release` 아래 `logs`,
  `screenshot`의 테스트 파일을 비운다.
- merge, tag, push, GitHub Release는 사용자 확인 없이 하지 않는다.
- 파괴적인 reset/checkout을 사용하지 않는다.
- 설계 변경은 `DECISIONS.md`
- 새 제약은 `KNOWN_ISSUES.md`
- 우선순위는 `TODO.md`
- 세션 종료 상태는 `SESSION.md`
- 큰 이정표는 `CHANGELOG.md`

문서에 추측을 사실처럼 적지 않는다.

### Native GUI release validation

Build/package using `scripts/Create-AppBundle.sh --rid osx-arm64 --output-dir dist/gui-arm64`
and `scripts/Package-Mac-Release.sh --rid osx-x64 --include-app --output-dir dist/gui-x64`.
Read `MACOS_GUI_PARITY.md` before calling the GUI equivalent to the Windows edition.
Check the actual native window, dirty-field navigation, device selection, each
settings page and graceful quit. Keep phone actions deferred when requested.
For isolated native UI checks, use a separate review app identifier and
`DXM_GUI_DATA_HOME` in the review copy's `LSEnvironment`, then re-sign that copy.
Never include those review overrides, test identities, settings or logs in delivery.
Run `GuiRunSettingsTests`, `GuiDesktopSettingsTests` and `GuiProtocolTests` with the
existing suite. `scripts/Test-MacDesktopControls.sh` exercises windowless native
routing, injection guards, key release and missing-symbol fallback without installing
a hook or sending keys. Packaging runs it before the managed tests.
After explicit OS permission approval, test F8 full/region/cancel/timeout, local/phone
PNG equality, mini-bar buttons/collapse/side, key modes and normal-stop restoration.
Record physical keyboard/model/OS results separately from windowless tests.

한국어: 새 GUI는 실제 창·편집 값 저장·기기 선택·각 설정 페이지·정상 종료를 확인한다.
사용자가 휴대폰 시험을 보류하면 시작·중지·무선·Companion 버튼을 시험하지 않는다.
별도 검토 앱의 데이터 홈과 식별자는 공개 패키지에 넣지 않는다. 구체적인 소스 대응과
미지원 기능을 확인한 뒤 공개 설명을 작성한다.
