# DX Manager for macOS — GUI preview

## English

This package is an **unreleased GUI preview**, based on the community macOS
2.0.2 runtime. The published 2.0.2 `.app` opens Terminal; this candidate's
`.app` opens a native Mac control window instead. macOS 14 or later is required.
Use arm64 for Apple Silicon and x64 for Intel. Both ZIPs contain the runtime,
ADB, scrcpy 4.1, proxy and notices; no Homebrew or separate .NET is needed.

Extract the complete ZIP. Open **DX Manager.app**, or move that whole app to
Applications. Keep its internal files intact. In Finder, select the ZIP and
matching checksum file from the same build; the checksum can be verified with:

```bash
release_version="<version>"
shasum -a 256 -c "DX-Manager-v${release_version}-macos-arm64.zip.sha256"
```

Replace arm64 with x64 on Intel. A checksum mismatch means the file must be
obtained again. The app's startup integrity check also rejects modified bundles.
The app has an ad-hoc signature, **not Developer ID/notarization**. macOS may
ask for approval in System Settings > Privacy & Security > Open Anyway, including
individual bundled components. Approval remains the user's decision.

1. Unlock a Galaxy, enable USB debugging, connect a data cable, and approve its RSA prompt.
2. Select that phone in the upper right. An unselected device edits common defaults only.
3. Use the left DeX / Single window 1–3 buttons. Set resolution, DPI, bitrate,
   FPS, screen off, stay awake, HID keyboard/mouse, start app and advanced arguments.
4. **Save settings** persists that physical device and mode. **Start** saves then
   starts it. Changes to a running session take effect after Stop and Start.
5. **Load apps** lists apps on the selected phone. Single-window slots require an
   app. Their saved app profiles can be saved, loaded or deleted independently.
6. Settings pages provide language/theme, startup, wireless connection/pairing,
   transfer folders, diagnostics/logs and explicitly selected-device Companion actions.
7. **Stop** stops the selected mode. **Command+Q** stops the app's sessions and
   waits for cleanup; keep the phone connected until the app exits.

In the focused DeX window, left Option+O turns the phone panel off, and left
Option+Shift+O turns it on. Panel off is different from security lock. Locking or
folding the phone can also lock DeX. HID requires a suitable physical keyboard
layout on the phone. These controls use scrcpy's existing session.

App settings: `~/Library/Application Support/DX Manager/config/settings.json`.
Logs: `~/Library/Logs/DX Manager`. Portable-folder settings remain separate.
The sibling `Start DX Manager.command` is the optional terminal interface.

In **Keyboard**, enable the desired key conversions, capture shortcuts and mini bar.
Use the permission buttons for **Accessibility** (key conversion / mini-bar actions)
and **Screen Recording** (capture). If macOS does not list the app automatically,
add the whole app with the plus button on the corresponding Privacy & Security page.
Restart the app if macOS requests it. Do not grant these permissions to bundled tools.
The mini-bar original-size button requests scrcpy 1:1 size, then keeps the window
inside the current display's usable area. If that size is too large, it scales down.
Right Option sends Shift+Space; F14 (Scroll Lock on external keyboards) toggles
Enter / Shift+Enter when enabled. Right Shift and right Command are delivered as
balanced left-modifier events. The capture default is F8: press once for selection,
again for the full window, or drag a region; Esc / timeout cancels. The mini bar's
camera captures the whole window immediately. PNGs are saved locally and optionally
sent to the same phone. Option+F8 stops the focused owned session.

Wireless operation, multiple phones, physical keyboard layouts and physical Intel
operation require separate hardware validation. See the source `docs/MACOS_GUI_PARITY.md` for the exact boundary.
The app does not silently install a Companion APK or add one to this package.

## 한국어

이 패키지는 커뮤니티 Mac 2.0.2 실행 코드를 바탕으로 한 **미공개 GUI 미리보기**입니다.
공개된 2.0.2의 `.app`은 Terminal을 열지만, 이 후보의 `.app`은 Mac 설정 창을 엽니다.
macOS 14 이상에서 M 시리즈는 arm64, Intel은 x64를 사용합니다. 실행에 필요한
런타임·ADB·scrcpy 4.1·proxy·라이선스가 포함되어 Homebrew나 .NET은 필요하지 않습니다.

ZIP 전체를 풀고 **DX Manager.app**을 엽니다. 앱 전체를 응용 프로그램 폴더로
옮길 수 있지만 내부 파일을 따로 이동하지 마세요. 위 명령으로 같은 빌드의
ZIP·체크섬을 확인할 수 있습니다. Intel에서는 arm64를 x64로 바꿉니다.
앱은 시작 시 무결성도 확인합니다. **Apple Developer ID 서명·공증은 없습니다.**
차단되면 시스템 설정 > 개인정보 보호 및 보안에서 '그래도 열기'를 확인해야 하며,
개별 구성요소도 승인이 필요할 수 있습니다. 승인은 사용자가 판단합니다.

1. Galaxy의 잠금을 풀고 USB 디버깅을 켠 뒤 데이터 케이블로 연결하고 RSA 승인을 합니다.
2. 오른쪽 위에서 해당 휴대폰을 선택합니다. 기기를 선택하지 않으면 공통 기본값을 편집합니다.
3. 왼쪽 DeX / 단일창 1~3에서 해상도·DPI·비트레이트·FPS, 화면 끄기·잠자기 방지,
   HID 키보드·마우스, 시작 앱과 고급 인자를 설정합니다.
4. **설정 저장**은 해당 물리 기기와 모드에 저장합니다. **시작**도 저장 후 실행합니다.
   실행 중 바꾼 값은 중지 후 다시 시작해야 적용됩니다.
5. **앱 목록 불러오기**로 선택 기기의 앱을 불러옵니다. 단일창에는 앱 선택이 필요하며,
   앱별 설정을 저장·불러오기·삭제할 수 있습니다.
6. 설정 메뉴에서 언어·테마·자동 실행, 무선 연결·페어링, 전송 폴더, 진단·로그와
   선택 기기의 Companion을 관리합니다.
7. **중지**는 선택한 모드만 종료합니다. **Command+Q**는 이 앱의 세션 정리를
   기다린 뒤 종료합니다. 끝날 때까지 휴대폰 연결을 유지하세요.

DeX 창을 클릭하고 왼쪽 Option+O로 휴대폰 패널을 끄고 Option+Shift+O로 켭니다.
패널 끄기는 보안 잠금과 다릅니다. 전원 버튼이나 접기로 잠그면 DeX도 잠길 수 있습니다.
HID 입력을 사용할 때는 휴대폰에서 물리 키보드 언어를 맞춰야 합니다.

앱 설정은 `~/Library/Application Support/DX Manager/config/settings.json`, 로그는
`~/Library/Logs/DX Manager`에 있습니다. 기존 포터블 폴더 설정과는 별개입니다.
같이 든 `Start DX Manager.command`는 선택형 터미널 인터페이스입니다.

**키 입력**에서 키 변환·캡처 단축키·미니바를 설정합니다. 해당 화면의 버튼으로
**손쉬운 사용**(키 변환·미니바 조작)과 **화면 기록**(캡처) 권한을 요청합니다.
앱이 목록에 자동으로 나타나지 않으면 개인정보 보호 및 보안의 해당 페이지에서
더하기 버튼으로 앱 전체를 추가하세요. macOS가 요구하면 앱을 다시 엽니다.
번들 안의 개별 실행 파일에 이 권한을 부여할 필요는 없습니다.
미니바의 원래 크기 버튼은 1:1 크기로 조정한 뒤 현재 모니터의 메뉴 막대·Dock을
제외한 영역 안으로 맞춥니다. 창 자체가 화면보다 크면 줄여서 표시합니다.
오른쪽 Option은 Shift+Space를 보내고, F14(외장 키보드 Scroll Lock)는 설정을
켰을 때 Enter / Shift+Enter를 전환합니다. 오른쪽 Shift·Command는 왼쪽 키로
누름·해제를 짝지어 전달합니다. F8 한 번은 선택, 다시 누르면 전체 창, 드래그는 영역,
Esc·시간 초과는 취소입니다. 미니바 카메라는 전체 창을 바로 저장합니다.
PNG를 Mac에 저장하고 선택에 따라 같은 휴대폰으로 전송합니다.
Option+F8은 현재 포커스가 있는 이 앱 소유 세션을 중지합니다.

무선·복수 기기·실물 키보드 배열·Intel 실기는 별도 검증 대상입니다.
정확한 대응 범위는 소스의 `docs/MACOS_GUI_PARITY.md`에 기록합니다.
Companion APK를 자동 설치하거나 패키지에 새로 추가하지 않습니다.
