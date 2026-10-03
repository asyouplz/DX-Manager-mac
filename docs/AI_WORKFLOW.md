# AI Workflow

## 시작

1. `docs/README.md`, `PROJECT_BRIEF.md`, `SESSION.md`, `TODO.md`를 읽는다.
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

Windows·Mac 휴대폰 DeX 숨김 기능 변경 시 추가로 다음을 실행한다. 첫 명령은
별도 Core 사본이 아니라 실제 Windows 서비스·모델 소스를 연결해 설정과
ADB 프로세스 수명주기를 검증한다. helper를 수정했으면 JDK 17로 다시 빌드하고
`LoopbackDexService.HelperSha256`도 새 번들 값과 함께 갱신한다.

```powershell
dotnet run --project DexManager.WindowsTests/DexManager.WindowsTests.csproj --configuration Release
.\scripts\Build-DexLoopback.ps1 -JavaHome 'C:\build-tools\jdk-17'
```

helper 재현 빌드는 `DXLoopback/README.md`와 전용 CI를 따른다. Mac에서 net462
참조 어셈블리로 컴파일을 확인한 것과 실제 Windows 전체 빌드·GUI 실행은
구분한다. 새 기능의 실기 항목은 `PHONE_PREVIEW_MODE.md`에 정리했다.

공개용 포터블 폴더와 ZIP은 저장소 루트에서 다음 명령으로 만든다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Package-Release.ps1
```

macOS 공개 후보는 사용자가 빌드하지 않아도 되도록 Apple Silicon arm64와 Intel
x64 self-contained ZIP을 미리 만든다. 지원 목표는 macOS 14 이상이다.

```bash
scripts/Package-Mac-Release.sh --rid osx-arm64
scripts/Package-Mac-Release.sh --rid osx-x64
```

macOS 스크립트는 현재 저장소의 다른 아키텍처용 개발 도구를 그대로 복사하지
않는다. DX Manager와 `DXMAdbProxy`를 지정된 RID로 publish하고, SHA-256을
고정한 공식 scrcpy 4.1의 해당 CPU 정적 아카이브를 넣는다. ZIP을 다시 풀어 실행
권한, Mach-O 아키텍처, 외부 Homebrew·사용자 경로 의존성, 버전, 필수 문서와
사용자 데이터·디버그 파일 제외를 확인한다. 파일 권한·순서·시각은
`SOURCE_DATE_EPOCH` 또는 현재 Git 커밋 시각으로 정규화한다. GitHub Actions
workflow는 Apple Silicon `macos-15`와 Intel `macos-15-intel`에서 각 패키지를
빌드·테스트해 PR artifact로 보관한다. `v*` 버전 태그에서는 ZIP과 체크섬을 다시 검증한 뒤 Release
초안을 만들고, 유지관리자가 초안을 확인한 뒤 공개한다.

패키징의 실행 검사는 `--version`, `--help`, proxy 자체 검사, ADB/scrcpy 버전
명령으로 제한한다. 실제 기기를 탐색하는 TUI를 열고 `Q`를 보내는 검사는 수행하지
않는다. 세션 종료 검증은 fake ADB 기반 회귀 테스트와 별도 승인된 실기로 구분한다.

시스템에 .NET Framework 4.6.2 Developer Pack이 없으면 참조 어셈블리 루트를
`-TargetFrameworkRootPath`로 지정하거나 현재 셸의
`DXM_TARGET_FRAMEWORK_ROOT` 환경 변수에 설정한다.

개발 산출물은 `DexManager\bin\Release`, 사용자 배포 산출물은
`dist\DX Manager`와 버전이 포함된 x64 ZIP으로 구분한다.
메이님에게 전달하거나 GitHub에 게시할 최종 릴리스 산출물은 항상
`E:\vs\dex system\dist`에서 생성·확인한다. C 드라이브의 Codex 작업 폴더에서
만든 `bin\Release`와 `dist`는 빌드·실기 검증용으로만 사용하며 정식 릴리스본으로
안내하지 않는다.
패키징은 생성한 배포 폴더만 검사하며 개발 폴더의 로그·스크린샷·설정을 삭제하지
않는다. Windows CI는 `scripts/Get-VerifiedCompanion.ps1`로 공식 v2.0.1 ZIP의
고정 해시와 서명 인증서를 검증한 기존 APK만 추출하고 `-CompanionApkSource`로
패키징에 전달한다. 자동 설치나 APK 포함 정책은 바꾸지 않는다.
Windows 검토용 ZIP은 네이티브 Windows에서 다시 풀어 ADB·scrcpy·proxy 실행,
필수 파일·체크섬·APK 서명과 사용자 데이터 제외를 검사한 뒤 artifact로 보관한다.
PR artifact는 메이님의 정식 릴리스 전달 위치를 대신하지 않는다.
패키지는 Scrcpy 4.1 런타임,
`tools\adb-proxy\DXMAdbProxy.exe`와 서명이 검증된
`tools\companion\DX-Companion.apk`를 반드시 포함해야 한다.
세 플랫폼 패키지 모두 `tools/loopback`의 사전 빌드 JAR·SHA-256·라이선스·고지를
포함한다. helper 변경 없이 새 JDK나 Android SDK를 사용자에게 요구하지 않는다.

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
- 빌드·커밋·배포 시 `bin\Debug`와 `bin\Release`의 사용자 로그·스크린샷을
  보존하고, 생성한 배포 폴더와 ZIP에 포함되지 않았는지 검사한다.
- merge, tag, push, GitHub Release는 사용자 확인 없이 하지 않는다.
- 파괴적인 reset/checkout을 사용하지 않는다.
- 설계 변경은 `DECISIONS.md`
- 새 제약은 `KNOWN_ISSUES.md`
- 우선순위는 `TODO.md`
- 세션 종료 상태는 `SESSION.md`
- 큰 이정표는 `CHANGELOG.md`

문서에 추측을 사실처럼 적지 않는다.
