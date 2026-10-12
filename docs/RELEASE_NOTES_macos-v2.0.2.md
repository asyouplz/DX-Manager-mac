# DX Manager for macOS 2.0.2 — Community distribution

## English

This release replaces 2.0.1 as the current community macOS download. Original project: [maze-mei/DX-Manager](https://github.com/maze-mei/DX-Manager); macOS port: [kimdongup/DX-Manager-mac](https://github.com/kimdongup/DX-Manager-mac); distribution: [asyouplz/DX-Manager-mac](https://github.com/asyouplz/DX-Manager-mac). The changes are maintained in [personal-fork PR #2](https://github.com/asyouplz/DX-Manager-mac/pull/2). macOS is distributed separately from the original project's Windows releases.

### Download

Requires **macOS 14 Sonoma or later**. No Homebrew or separate .NET installation is needed.

| Mac | Package | Checksum |
| --- | --- | --- |
| Apple Silicon (M-series) | [arm64 ZIP](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.0.2/DX-Manager-v2.0.2-macos-arm64.zip) | [SHA-256](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.0.2/DX-Manager-v2.0.2-macos-arm64.zip.sha256) |
| Intel | [x64 ZIP](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.0.2/DX-Manager-v2.0.2-macos-x64.zip) | [SHA-256](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.0.2/DX-Manager-v2.0.2-macos-x64.zip.sha256) |

Extract the entire ZIP and open **DX Manager.app**. You may move the whole app to Applications. The original **Start DX Manager.command** remains available for portable-folder use; keep its sibling files together. Both launch the terminal menu: `1` starts DeX, `2` stops it, and `Q` stops sessions and exits. Enable USB debugging on the phone, connect it, unlock it and approve the RSA prompt when required.

### What changed

- The menu, saved preferences and new DeX/single-app windows now use the selected phone's profile. Changing one phone's preferences does not overwrite another phone's settings or common defaults.
- Focus the DeX/scrcpy window: left **Option+O** turns the phone panel off; **Option+Shift+O** turns it on. Terminal `O` shows this help only. The running scrcpy session owns screen restoration.
- The optional standalone app includes the runtime, scrcpy 4.1, ADB and ADB proxy. It verifies integrity and opens the terminal menu. App settings are stored in `~/Library/Application Support/DX Manager/config/settings.json`; portable-folder settings remain separate and are not automatically imported.

**Screen off is not a security unlock.** A lock button, folding or a security lock may also lock DeX. Unlock the phone to resume. This is not a confirmed fix for Galaxy Z Flip6 folding/manual-lock behavior.

**Apple Developer ID signing and notarization are not included.** If blocked, attempt launch once, close the warning, then review **System Settings > Privacy & Security > Open Anyway** for the component you trust. The app or bundled tools may need individual approvals. The launcher does not remove quarantine or change system security settings. Read [the first-launch and package guide](https://github.com/asyouplz/DX-Manager-mac/blob/macos-v2.0.2/docs/PACKAGE_README_MACOS.md).

### Source and verification

- Source is archived at [`macos-v2.0.2`](https://github.com/asyouplz/DX-Manager-mac/tree/macos-v2.0.2). It includes the native-tool selection prerequisite from still-open [PR #5](https://github.com/maze-mei/DX-Manager/pull/5).
- [Earlier CI run 38210807278 (withdrawn upstream PR)](https://github.com/maze-mei/DX-Manager/actions/runs/38210807278) passed on both Apple Silicon and Intel runners, including native package smoke checks. These are software checks without a connected Galaxy.
- Final 2.0.2 local Release build: zero warnings/errors; xUnit **121/121**, multi-device tests **39/39**.
- Both final packages: SHA-256, ZIP CRC, required files/licenses, executable permissions, architecture and private-data exclusion passed. Both app signatures passed deep/strict verification. Apple Silicon version/help/integrity checks passed; a tampered app copy was rejected. Intel was cross-packaged locally.
- The same runtime was tested as **2.0.2-preview.2** on Apple Silicon with USB **SM-S942N**, Android 17 / SDK 37 / One UI property `90000`. The user confirmed normal DeX during phone-panel on/off. `2` and active-session `Q` restored the panel, overlay and original power settings, and exited without remaining DX Manager/scrcpy processes. Final 2.0.2 changes version metadata/documentation; it is not claimed as a second physical-device test.
- Galaxy Z Flip6, folding/manual lock, other firmware, Wi-Fi switching/file-transfer regressions, physical Intel/Galaxy operation, Finder launch UI and first approval from a quarantined browser download remain unverified.
- The previous 2.0.1 tag and files are preserved for existing links and rollback; use the packages above for this update.

Download the ZIP and matching checksum into one folder, then run:

```bash
shasum -a 256 -c DX-Manager-v2.0.2-macos-arm64.zip.sha256
```

For Intel, replace `arm64` with `x64`. The result must be `OK`.

```text
98dc4887acd434063be061518d0fca60401e289cd23291d3ab4bb4191041f392  DX-Manager-v2.0.2-macos-arm64.zip
562bedebfbf88b41278e3611890fcc566a1d771cf017596b5bd69f1288165faa  DX-Manager-v2.0.2-macos-x64.zip
```

## 한국어

기존 2.0.1을 잇는 **macOS 2.0.2 커뮤니티 배포본**입니다. 원본은 [maze-mei/DX-Manager](https://github.com/maze-mei/DX-Manager), macOS 포팅은 [kimdongup/DX-Manager-mac](https://github.com/kimdongup/DX-Manager-mac)이며 이 포크에서 별도로 배포합니다. 수정은 [개인 배포 저장소 PR #2](https://github.com/asyouplz/DX-Manager-mac/pull/2)에서 관리합니다. macOS 파일은 원본 프로젝트의 Windows 릴리스와 별도로 배포합니다.

### 다운로드와 실행

위 표에서 **M 시리즈 Mac은 arm64**, **Intel Mac은 x64** ZIP과 체크섬을 받으십시오. **macOS 14 Sonoma 이상**이 필요하며 Homebrew나 .NET을 따로 설치할 필요가 없습니다.

ZIP 전체를 풀고 **DX Manager.app**을 여십시오. 앱 전체를 응용 프로그램 폴더로 옮겨도 됩니다. 기존 **Start DX Manager.command**도 제공하며, 이 포터블 실행기를 사용할 때는 같은 폴더의 파일들을 함께 유지하십시오. 두 방식 모두 터미널 메뉴를 엽니다. `1`은 DeX 시작, `2`는 중지, `Q`는 세션을 정리하고 종료합니다. 휴대폰의 USB 디버깅을 켜고 연결한 뒤 잠금을 풀고, 필요하면 RSA 승인창에서 허용하십시오.

### 달라진 점

- 메뉴에 표시되는 설정, 저장하는 설정과 새 DeX·단일창에 적용하는 설정을 선택한 휴대폰 기준으로 맞췄습니다. 다른 휴대폰이나 공통 기본값을 덮어쓰지 않습니다.
- DeX/scrcpy 창을 클릭하고 왼쪽 **Option+O**로 휴대폰 패널을 끄고 **Option+Shift+O**로 켭니다. 터미널의 `O`는 사용법만 표시합니다. 같은 scrcpy 세션이 종료 시 화면 복원을 관리합니다.
- 선택형 앱 묶음에는 런타임·scrcpy 4.1·ADB·ADB proxy가 포함됩니다. 앱 무결성을 검사하고 기존 터미널 메뉴를 엽니다. 앱 설정은 `~/Library/Application Support/DX Manager/config/settings.json`에 저장합니다. 기존 포터블 폴더 설정은 별도로 유지하며 자동으로 가져오지 않습니다.

**휴대폰 패널 끄기와 보안 잠금은 다릅니다.** 전원·잠금 버튼, 접기 또는 보안 잠금으로 DeX도 잠길 수 있으며 그때는 휴대폰에서 잠금을 풀어야 합니다. Flip6 접기·수동 잠금 문제가 해결됐다고 확인한 배포는 아닙니다.

**Apple Developer ID 서명·공증은 없습니다.** 차단되면 한 번 실행을 시도하고 경고를 닫은 뒤 **시스템 설정 > 개인정보 보호 및 보안 > 그래도 열기**에서 신뢰하는 구성요소를 승인하십시오. 앱이나 포함된 도구마다 승인이 남을 수 있습니다. 실행기가 quarantine을 제거하거나 Mac 전체 보안 설정을 바꾸지는 않습니다. [최초 실행·패키지 안내](https://github.com/asyouplz/DX-Manager-mac/blob/macos-v2.0.2/docs/PACKAGE_README_MACOS.md)를 참고하십시오.

### 검증 범위

[철회한 원작자 PR의 기존 CI 38210807278](https://github.com/maze-mei/DX-Manager/actions/runs/38210807278)도 Apple Silicon·Intel 실행 환경 모두 통과했습니다. 각 환경의 패키지 실행 검사를 포함하며 휴대폰을 연결한 실기는 아닙니다.

최종 2.0.2 로컬 빌드는 경고·오류 0, xUnit 121개와 다중 기기 테스트 39개를 통과했습니다. 두 ZIP의 체크섬·압축 무결성·필수 파일·라이선스·실행 권한·아키텍처·개인 파일 제외와 앱 서명을 확인했습니다. Apple Silicon에서 버전·도움말·무결성 검사는 정상이며, 변조한 복사본은 거부했습니다. Intel 파일은 로컬에서 교차 패키징했습니다.

동일한 실행 코드는 **2.0.2-preview.2**로 USB **SM-S942N**(Android 17, SDK 37, One UI 속성 `90000`)에서 시험했습니다. 사용자가 휴대폰 화면 켜기·끄기 중 DeX 정상 표시를 확인했고, `2` 중지와 실행 중 `Q` 종료에서 화면·가상 화면·원래 전원 설정 복원 및 프로세스 종료를 확인했습니다. 최종 2.0.2는 버전 표기·문서와 패키지를 갱신한 것이며, 최종 파일의 실기를 다시 수행했다고 표기하지 않습니다.

Galaxy Z Flip6, 접기·수동 잠금, 다른 펌웨어, 무선 전환·파일 전송 회귀, 실제 Intel/Galaxy 동작, Finder 실행 화면 및 브라우저 다운로드 최초 승인 과정은 별도 확인 대상입니다. 소스 태그는 `macos-v2.0.2`이며 미병합 PR #5의 선행 수정도 포함합니다.

이전 2.0.1 태그·파일은 기존 링크와 되돌리기 용도로 보존합니다. 이번 변경은 위의 2.0.2 파일을 받으면 됩니다. ZIP과 체크섬을 같은 폴더에 두고 위의 `shasum` 명령 결과가 `OK`인지 확인하십시오. Intel 파일은 명령의 `arm64`를 `x64`로 바꿉니다.
