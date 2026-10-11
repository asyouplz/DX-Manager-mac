# DX Manager for macOS v2.0.1 — Community distribution

## English

This is the macOS distribution maintained in [asyouplz/DX-Manager-mac](https://github.com/asyouplz/DX-Manager-mac). It redistributes the existing Apple Silicon and Intel portable packages without modifying their contents. The original project is [maze-mei/DX-Manager](https://github.com/maze-mei/DX-Manager); the macOS port was contributed through [kimdongup/DX-Manager-mac](https://github.com/kimdongup/DX-Manager-mac). This release is published by this fork and is not an official upstream release.

### Download and run

| Mac | Portable ZIP | SHA-256 file |
| --- | --- | --- |
| Apple Silicon (M-series) | [arm64 ZIP](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.0.1/DX-Manager-v2.0.1-macos-arm64.zip) | [arm64 checksum](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.0.1/DX-Manager-v2.0.1-macos-arm64.zip.sha256) |
| Intel | [x64 ZIP](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.0.1/DX-Manager-v2.0.1-macos-x64.zip) | [x64 checksum](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.0.1/DX-Manager-v2.0.1-macos-x64.zip.sha256) |

Requires macOS 14 Sonoma or later. The ZIP includes the .NET runtime, scrcpy 4.1, ADB, and the ADB proxy; Homebrew and a separate .NET installation are not required. Extract the entire ZIP and double-click `Start DX Manager.command`. This opens the terminal menu, not a Windows-style settings window. Keep every file and folder together. The macOS packages do not include a Companion APK.

For detailed setup, USB authorization, cleanup, and first-launch instructions, see the [portable package guide](https://github.com/asyouplz/DX-Manager-mac/blob/macos-v2.0.1/docs/PACKAGE_README_MACOS.md).

### Source and verification

- Distribution tag: `macos-v2.0.1`. The package filename version remains `2.0.1` to preserve the original ZIPs and checksums.
- Exact build and tag commit: [`fcbcaa124e6f978e2ffc4283854d4d3489a1dc1c`](https://github.com/asyouplz/DX-Manager-mac/commit/fcbcaa124e6f978e2ffc4283854d4d3489a1dc1c).
- Original build: [macOS portable packages, run 35304622556](https://github.com/maze-mei/DX-Manager/actions/runs/35304622556), built on 2026-09-18.
- The build used the temporary merge commit for [upstream PR #5](https://github.com/maze-mei/DX-Manager/pull/5), which was still open when this distribution was prepared. It includes macOS native-tool selection fixes. Its source tree is identical to PR head `cc7dc401245da5802c0e944dc9f063ce3a2fd09f`.
- Both original CI jobs passed the Release build with zero warnings/errors, 106 unit/integration tests, 39 multi-device tests, and portable-package verification.
- Redistribution checks passed for both ZIPs: SHA-256 sidecars, archive integrity, executable permissions, required tools/licenses, and exclusion of personal settings, logs, debug files, signing secrets, and APKs. On an Apple Silicon Mac, the packaged program returned version `2.0.1` and help successfully; bundled `adb version` also succeeded. No device-control command was run.

The packages are not signed with an Apple Developer ID or notarized. macOS may require first-launch approval. A complete Galaxy DeX session, USB/Wi-Fi switching, file transfer, and cleanup were not re-tested on physical devices for this distribution. Hardware and One UI compatibility remain subject to the package guide's limits.

Download the matching ZIP and checksum into one folder. For Apple Silicon:

```bash
shasum -a 256 -c DX-Manager-v2.0.1-macos-arm64.zip.sha256
```

Use `x64` instead of `arm64` for Intel. The result must be `OK`.

```text
102869df528261656813484777c6d06090c0f41f9538fe5c739e6f4f45edc0cf  DX-Manager-v2.0.1-macos-arm64.zip
81ba424d6d43ff160b349fd2020881ee007ea4fa71c0d261b5dfecb03a731db3  DX-Manager-v2.0.1-macos-x64.zip
```

## 한국어

이 릴리스는 [asyouplz/DX-Manager-mac](https://github.com/asyouplz/DX-Manager-mac)에서 관리하는 별도 macOS 배포본입니다. 기존 Apple Silicon·Intel 포터블 패키지의 내용을 변경하지 않고 제공합니다. 원본 프로젝트는 [maze-mei/DX-Manager](https://github.com/maze-mei/DX-Manager)이며, macOS 포팅은 [kimdongup/DX-Manager-mac](https://github.com/kimdongup/DX-Manager-mac)을 통해 기여됐습니다. 원본 프로젝트의 공식 릴리스와는 별도로 이 포크에서 게시합니다.

### 다운로드와 실행

위 표에서 **M 시리즈 Mac은 arm64**, **Intel Mac은 x64** ZIP과 같은 이름의 체크섬 파일을 받으십시오. 공개 릴리스 파일은 GitHub 로그인 없이 다운로드할 수 있습니다.

최소 운영체제는 macOS 14 Sonoma입니다. .NET 런타임, scrcpy 4.1, ADB와 ADB proxy가 포함돼 있어 Homebrew나 별도 .NET 설치가 필요하지 않습니다. ZIP 전체를 풀고 `Start DX Manager.command`를 더블클릭하면 터미널 메뉴가 열립니다. Windows 형태의 설정 창은 아니며, 압축을 푼 파일과 폴더를 함께 유지해야 합니다. macOS ZIP에는 Companion APK가 포함되지 않습니다.

휴대폰 USB 디버깅 승인, 종료 시 정리와 최초 실행 승인은 [포터블 패키지 안내](https://github.com/asyouplz/DX-Manager-mac/blob/macos-v2.0.1/docs/PACKAGE_README_MACOS.md#한국어)를 참고하십시오.

### 소스와 검증 범위

- 배포 태그는 `macos-v2.0.1`입니다. 원본 ZIP과 체크섬을 보존하므로 파일명의 버전은 `2.0.1`을 유지합니다.
- 태그는 실제 빌드 커밋 `fcbcaa124e6f978e2ffc4283854d4d3489a1dc1c`를 가리킵니다.
- 2026-09-18의 [원본 Actions 실행 35304622556](https://github.com/maze-mei/DX-Manager/actions/runs/35304622556)에서 만든 파일입니다.
- 배포 준비 당시 미병합 상태였던 [원본 PR #5](https://github.com/maze-mei/DX-Manager/pull/5)의 임시 병합 커밋으로 빌드됐으며, Mac 아키텍처별 실행 도구 선택 보정을 포함합니다. 소스 내용은 PR head `cc7dc401245da5802c0e944dc9f063ce3a2fd09f`와 같습니다.
- 원본 CI에서 두 아키텍처 모두 Release 빌드 경고·오류 0, 단위·통합 테스트 106개, 다중 기기 테스트 39개와 패키지 검증을 통과했습니다.
- 이번 재배포에서도 두 ZIP의 체크섬·압축 무결성·실행 권한·필수 도구와 라이선스, 개인 설정·로그·디버그 파일·서명 비밀·APK 제외를 확인했습니다. Apple Silicon Mac에서 프로그램의 버전 `2.0.1`·도움말 출력과 번들 `adb version` 실행도 확인했습니다. 휴대폰 제어 명령은 실행하지 않았습니다.

Apple Developer ID 서명과 공증은 적용되지 않아 최초 실행 시 macOS 승인이 필요할 수 있습니다. 이번 배포 과정에서는 실제 Galaxy의 DeX 전체 동작, USB·무선 전환, 파일 전송과 종료 정리를 다시 시험하지 않았습니다. 기기·One UI 호환성은 패키지 안내의 확인 범위를 따릅니다.

ZIP과 체크섬 파일을 같은 폴더에 저장한 뒤 위의 `shasum` 명령을 실행해 `OK`를 확인하십시오. Intel Mac 파일은 명령의 `arm64`를 `x64`로 바꿉니다. 두 ZIP의 SHA-256은 위에 기재된 값과 동일합니다.
