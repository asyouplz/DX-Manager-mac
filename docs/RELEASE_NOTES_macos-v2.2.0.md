# DX Manager for macOS 2.2.0 — Hide phone preview (experimental)

## English

This community macOS release ports the opt-in **Hide phone preview** DeX mode
from the Windows edition ([maze-mei/DX-Manager#8](https://github.com/maze-mei/DX-Manager/pull/8))
to the native Mac app. Only that feature was ported; the 2.1.0 Mac GUI, scrcpy
4.1 and all other behavior are unchanged.

### Download and run

Requires **macOS 14 Sonoma or later**.

| Mac | ZIP | Checksum |
| --- | --- | --- |
| Apple Silicon (M-series) | [arm64 ZIP](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.2.0/DX-Manager-v2.2.0-macos-arm64.zip) | [SHA-256](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.2.0/DX-Manager-v2.2.0-macos-arm64.zip.sha256) |
| Intel | [x64 ZIP](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.2.0/DX-Manager-v2.2.0-macos-x64.zip) | [SHA-256](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.2.0/DX-Manager-v2.2.0-macos-x64.zip.sha256) |

Extract the complete ZIP and open **DX Manager.app**.

### Changes from 2.1.0

- **Hide phone preview (experimental)** on the DeX page, and item 8 in the
  terminal settings. Off by default, saved per phone, changeable only while DeX
  is stopped. Samsung wireless DeX is requested over the phone's own
  `127.0.0.1` by a SHA-256-pinned helper; scrcpy still carries video, audio and
  input. Resolution, DPI and phone screen-off are disabled in this mode, and
  scrcpy screen-power arguments are rejected.
- Session heartbeat every 3 s; Stop, channel EOF or 15 s without a heartbeat
  triggers phone-side cleanup of only the owned DeX connection.
- Existing overlays or external displays are never removed by this mode.
- Hardened-runtime entitlements and a secret-gated Developer ID signing and
  notarization path in the packaging script and CI
  ([setup](https://github.com/asyouplz/DX-Manager-mac/blob/macos-v2.2.0/docs/MACOS_SIGNING.md)).
- 40 new host-side tests (protocol, token, power-argument, helper hash and
  settings persistence).

### Signing status of this release

These packages are **ad-hoc signed and not notarized**, because no Apple
Developer ID certificate is configured for the repository yet. macOS will show
"Apple could not verify 'DX Manager' is free of malware". For this download,
use System Settings > Privacy & Security > **Open Anyway**, or remove the
quarantine yourself:

```bash
xattr -dr com.apple.quarantine "/path/to/DX Manager"
```

A notarized 2.2.x build follows once the signing secrets are added.

### Verification boundary

CI on Apple Silicon and Intel runners builds with warnings as errors, runs the
managed, multi-device and native-controls suites, and verifies each package.
**Hidden-preview behavior on a real Galaxy from a Mac, actual disconnect cleanup
time and Intel hardware were not physically tested.**

## 한국어

Windows 판의 선택 기능 **휴대폰 미리보기 숨김**([maze-mei/DX-Manager#8](https://github.com/maze-mei/DX-Manager/pull/8))만
Mac 앱으로 옮긴 커뮤니티 릴리스입니다. 2.1.0 GUI·scrcpy 4.1과 다른 동작은 그대로입니다.

- DeX 화면에 **휴대폰 미리보기 숨김 (실험)**, 터미널 설정에 8번 항목을 추가했습니다.
  기본값은 꺼짐이며 휴대폰별로 저장하고 DeX가 중지된 상태에서만 바꿀 수 있습니다.
- 해시가 고정된 보조 파일이 휴대폰 내부 `127.0.0.1`로 삼성 무선 DeX를 연결하고,
  화면·오디오·입력은 기존 scrcpy가 처리합니다. 이 모드에서는 해상도·DPI·화면 끄기를
  사용하지 않고 화면 전원 관련 scrcpy 인자를 거부합니다.
- 3초 신호, 중지·연결 종료·15초 신호 손실 시 자신이 만든 DeX 연결만 정리합니다.
- Developer ID 서명·공증 경로를 추가했지만, 저장소에 인증서가 아직 없어 이번 패키지는
  **ad-hoc 서명이며 공증되지 않았습니다.** 실행 시 경고가 나오면 그래도 열기 또는 위
  `xattr` 명령을 사용하세요. Secret 등록 후 공증된 2.2.x를 배포합니다.
- Mac에서의 실제 Galaxy 동작·연결 해제 정리 시간·Intel 실기는 **미확인**입니다.
