# Building the Windows 2.5.0 source

## English

This page describes the Windows WinForms branch, not the separate WinUI Store product or macOS port.
The reviewed local branch is `feature/portable-backport-v2.0.1-20260928`. Do not merge Store code into it.

### Prerequisites

- Visual Studio 2019/MSBuild with C# and .NET Framework 4.6.2 reference assemblies.
- Windows x64 output. The Windows app has no external NuGet dependencies.
- The verified official shared Companion component: `integration/CompanionRelease.cs`, `release.json`,
  `release/DX-Companion.apk`, required notices and the shared build/verification scripts.
- scrcpy 5.0.1 files matching `scripts/scrcpy-runtime.json`; keep the legacy ADB files for Windows 7/8.1.

### Shared Companion boundary

In the maintainer's workspace the canonical component is `E:\vs\DX Companion Shared`.
Both PC products consume its generated constants and official APK. Android code is edited and signed
there once; the old `DXDisplayCleanup` tree is a migration notice, not a second editable Android project.
Private test APKs must not be substituted for the official component.

The current public `main` still describes the older in-repository Android source. Before publishing the
2.5.0 source, the release must also provide a public, pinned copy/dependency of the matching shared
component and document how to obtain it. A plain clone of the currently prepared portable branch
without this component is **not a verified standalone build**. This source-distribution gate is tracked
in [the documentation audit](DOCUMENTATION_AUDIT_2026-10-16.md); it does not change the scanned binary ZIP.

Do not resolve a missing dependency by silently restoring the historical per-product APK/source or
using the private test package. Validate the official version, package, certificate and APK hash.

### Build with the verified component present

Open `DexManager.sln` in Visual Studio and build x64 Release, or use MSBuild:

```powershell
MSBuild.exe .\DexManager.sln /t:Build /p:Configuration=Release
```

If the component is stored elsewhere, specify its root explicitly:

```powershell
MSBuild.exe .\DexManager.sln /t:Build /p:Configuration=Release '/p:CompanionSharedRoot=C:\src\DX Companion Shared'
```

The MSBuild property changes the C# project input. Current packaging wrappers still locate the sibling
`DX Companion Shared` directory; the public-source preparation must close that packaging dependency too.

If the targeting pack is not installed system-wide, pass the root containing
`.NETFramework\v4.6.2` using `/p:TargetFrameworkRootPath=...`. Developer output is
`DexManager/bin/Release`; it is separate from a user distribution.

### Verify and package

In the approved maintainer workspace, `scripts/Verify-OfficialBuild.ps1` builds and runs the actual
assembly regression/UI checks. The UI fixtures use the product's executable config to match its
.NET Framework 4.6.2 runtime behavior. Device commands are blocked in those fixtures.

- `scripts/Build-PortablePreview.ps1`: overwrite the single fixed preview and preserve user data.
- `scripts/Build-FinalRelease.ps1`: create the clean 2.5.0 final folder after backing up the old final.
  It excludes settings and saved consent so a new user sees first-run acknowledgement.
- `scripts/Package-Release.ps1`: explicit runtime/license list, compact README and no external guide images.
  `-SkipBuild` requires already verified output; `-NoArchive` creates a folder without a ZIP.

The first two scripts use the maintainer's fixed workspace paths. They are not generic commands for an
arbitrary source clone. Use `Package-Release.ps1` with an explicit output folder for another workspace.

First-run acknowledgement, personal settings, logs, captures, receive data, PDBs, signing inputs and
private test artifacts must not enter the public archive. The two original scrcpy PNGs are runtime
resources. Never disable a machine's execution policy just to bypass a blocked script.

### Android builds

See [the migration notice](../DXDisplayCleanup/README.md). The canonical `Build-Companion.ps1` requires
workroom/chat attribution and an explicit trusted signing-properties path. It runs unit tests/lint,
verifies the official package/certificate and updates the one official APK and Windows constants.
Android source builds use JDK 17, compile/target API 36 and min API 33. Signing keys and passwords are
never copied into the repository or release. Do not claim a source/APK rebuild after a documentation-only edit.

## 한국어

이 문서는 Windows WinForms 2.5.0 작업선 기준입니다. Store WinUI 제품과 macOS 이식은 별도입니다.
Visual Studio 2019/MSBuild, .NET Framework 4.6.2 참조 어셈블리와 검증된 공용 Companion이 필요합니다.

공용 정식 Android 원본은 `E:\vs\DX Companion Shared`에서 한 번만 관리합니다.
PC는 그 안의 C# 상수·공식 APK를 사용하며, 예전 `DXDisplayCleanup`을 다시 작업용 원본으로 되살리지 않습니다.
프로젝트의 `CompanionSharedRoot` 속성으로 다른 공용 폴더를 지정할 수 있습니다.

현재 공개 main의 옛 Android 소스 배치와 로컬 공용 배치는 다릅니다. **2.5.0 소스를 공개하기 전에는
일치하는 공용 컴포넌트의 공개 사본/의존성과 가져오는 방법을 함께 준비해야 합니다.** 해당 폴더가 없는
독립 clone 빌드는 아직 검증되지 않았습니다. 이는 소스 배포 준비 항목이며 검사 완료 ZIP을 바꾸는 작업이 아닙니다.

검증과 포터블/최종 패키징은 위 스크립트를 사용합니다. 고정 경로 스크립트는 개발자의 승인된 작업 폴더용입니다.
개인 설정·동의 기록·로그·캡처·수신 파일·서명 비밀·개발 도구는 배포본에서 제외합니다.
자세한 현황은 [문서 감사](DOCUMENTATION_AUDIT_2026-10-16.md), 산출물은
[2.5.0 검증 기록](VERIFICATION_v2.5.0.md)을 확인하세요. 커밋·업로드·태그·릴리스 생성은 별도 지시 후 진행합니다.
