# DX Manager for macOS 2.1.0 — Native GUI

## English

This community macOS release replaces the `.app` terminal launcher with a native
Mac control window. It is maintained by [asyouplz](https://github.com/asyouplz),
based on [maze-mei/DX-Manager](https://github.com/maze-mei/DX-Manager) and the
macOS port by [kimdongup](https://github.com/kimdongup/DX-Manager-mac).
Mac and Windows release numbers are maintained separately.

### Download and run

Requires **macOS 14 Sonoma or later**. Both ZIPs contain **DX Manager.app**, .NET
runtime, scrcpy 4.1, ADB and ADB proxy. Homebrew and a separate .NET install are not needed.

| Mac | ZIP | Checksum |
| --- | --- | --- |
| Apple Silicon (M-series) | [arm64 ZIP](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.1.0/DX-Manager-v2.1.0-macos-arm64.zip) | [SHA-256](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.1.0/DX-Manager-v2.1.0-macos-arm64.zip.sha256) |
| Intel | [x64 ZIP](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.1.0/DX-Manager-v2.1.0-macos-x64.zip) | [SHA-256](https://github.com/asyouplz/DX-Manager-mac/releases/download/macos-v2.1.0/DX-Manager-v2.1.0-macos-x64.zip.sha256) |

Extract the complete ZIP, then open **DX Manager.app**. You may move the whole
app to Applications. Select the connected Galaxy, choose DeX or a single-window
slot, adjust settings and click Start. The optional `.command` still opens the
terminal interface. [First launch and use](https://github.com/asyouplz/DX-Manager-mac/blob/macos-v2.1.0/docs/PACKAGE_README_MACOS.md).

### Changes from 2.0.2

- Native buttons and checkboxes for DeX, three single-window slots, device profiles,
  language/theme, connection, transfer settings, diagnostics and logs.
- Focused-window Mac key conversion: right Option language switching, right Shift
  compatibility and configurable capture/stop shortcuts. F14 toggles Enter behavior.
- F8 whole-window/region PNG capture, Esc/timeout cancellation, and optional transfer
  to the same phone. The mini-bar camera captures the whole window directly.
- Attached mini bar for phone panel off/on, power, fullscreen, original size, capture,
  manager opening and collapse. The original-size button keeps the window within
  the current Mac display. Missing system icons fall back to usable text buttons.
- Owned-session cleanup on Stop/quit, stable device selection and preserved settings.
- A source mapping and read-only checker for integrating later original-project
  updates. The recorded upstream baseline remains `2a1ec107450d8755e3691e9fa52aa086ed034e8d`;
  this is not a claim that a later Windows release has already been integrated.

### Permissions and validation limits

**Developer ID signing and Apple notarization are not included.** Gatekeeper may
require **System Settings > Privacy & Security > Open Anyway** for the app or tools.
For key/mini-bar actions grant **Accessibility**, and for capture grant **Screen
Recording**, using the buttons in Keyboard settings. Add the whole `.app` manually
if macOS does not list it, and restart when requested. These are separate from
first-launch approval. The package does not remove quarantine or weaken Mac security.

Automated validation covers **142 managed tests, 39 multi-device tests and 17 native
checks**, plus dual-architecture packaging, signatures, executable permissions,
checksums, archive integrity and private-data exclusion. Physical checks on an
Apple Silicon Mac with USB **SM-S942N / Android 17** covered panel off/on, language
switching/right Shift, full/region/camera captures and matching phone copies,
Esc/timeout cancellation, mini-bar actions, resize correction and normal cleanup.
These were performed on the preceding GUI review builds; final 2.1.0 changes
release labels, documentation and CI packaging, not the tested phone behavior.

F14 was unavailable on the tested keyboard. Enter toggling, alternate ADB input,
wireless/simultaneous phones, single-window hardware, external displays, other
Galaxy models and Intel/Galaxy operation remain unverified. Capture includes the
Mac window title bar. Security lock/folding can still lock DeX. This is not full
Windows platform parity; see [the scope table](https://github.com/asyouplz/DX-Manager-mac/blob/macos-v2.1.0/docs/MACOS_GUI_PARITY.md).

Settings and logs remain outside the signed app. Existing portable-folder settings
are not silently migrated. Companion APK inclusion/automatic installation is unchanged.
The 2.0.1 and 2.0.2 release files remain available for existing links and rollback.
To verify a ZIP beside its matching checksum file:

```bash
shasum -a 256 -c DX-Manager-v2.1.0-macos-arm64.zip.sha256
```

Use `x64` instead of `arm64` on Intel. Source: [`macos-v2.1.0`](https://github.com/asyouplz/DX-Manager-mac/tree/macos-v2.1.0).

## 한국어

기존 `.app`의 터미널 실행기를 **Mac 네이티브 설정 창**으로 바꾼 커뮤니티 2.1.0입니다.
[maze-mei/DX-Manager](https://github.com/maze-mei/DX-Manager)와
[kimdongup](https://github.com/kimdongup/DX-Manager-mac)님의 macOS 포팅을 바탕으로
[asyouplz](https://github.com/asyouplz)가 별도로 관리합니다. Mac·Windows 버전 번호는
독립적으로 관리합니다.

### 다운로드와 실행

**macOS 14 이상**에서 위 표의 **M 시리즈는 arm64**, **Intel은 x64** ZIP을 받으세요.
두 파일 모두 **DX Manager.app**, 런타임·scrcpy 4.1·ADB·proxy를 포함합니다.
Homebrew나 .NET 설치 없이 ZIP을 풀고 앱을 열면 됩니다. 앱 전체를 응용 프로그램
폴더로 옮길 수 있습니다. 연결된 Galaxy를 선택하고 DeX·단일창 설정 후 시작하세요.
`.command`는 선택형 터미널 인터페이스입니다. [최초 실행·사용법](https://github.com/asyouplz/DX-Manager-mac/blob/macos-v2.1.0/docs/PACKAGE_README_MACOS.md).

### 2.0.2에서 바뀐 내용

- DeX·단일창 1~3·기기별 설정·언어/테마·연결·전송·진단·로그를 버튼과 체크박스로 조작합니다.
- 현재 DeX 창에 오른쪽 Option 한/영 전환과 오른쪽 Shift 보정 등을 적용합니다.
  캡처·중지 단축키를 설정할 수 있으며, F14로 Enter 동작을 전환합니다.
- F8 전체·영역 PNG 캡처, Esc·시간 초과 취소, 같은 휴대폰으로 전송을 지원합니다.
- 미니바에서 화면 켜기·끄기, 전원, 전체화면, 원래 크기, 캡처, 설정 창, 접기를 조작합니다.
  크기 조정 뒤 창이 Mac 화면 밖으로 나가지 않게 보정하며, 없는 아이콘은 글자로 대체합니다.
- 중지·종료 시 이 앱의 세션을 정리하며, 기기 선택 메뉴와 설정 보존을 보완했습니다.
- 원본 대응표와 업데이트 검사 도구를 포함합니다. 원본 기준 커밋은
  `2a1ec107450d8755e3691e9fa52aa086ed034e8d`이며, 이후 Windows 버전을 이미
  반영했다는 뜻은 아닙니다.

### 권한과 검증 범위

**Apple Developer ID 서명·공증은 없습니다.** 최초 실행 때 앱이나 개별 도구를
**시스템 설정 > 개인정보 보호 및 보안 > 그래도 열기**로 승인해야 할 수 있습니다.
키 입력 화면의 버튼으로 **손쉬운 사용**과 **화면 기록** 권한을 요청합니다.
자동 목록에 없으면 앱 전체를 직접 추가하고 macOS가 요구하면 재시작하세요.
이는 최초 실행 승인과 별개입니다. quarantine이나 Mac 전체 보안 설정을 바꾸지 않습니다.

자동 검증은 **관리형 테스트 142개·다중 기기 39개·네이티브 17개**, 두 아키텍처
패키징과 서명·권한·체크섬·압축 무결성·개인 파일 제외를 포함합니다.
Apple Silicon과 USB **SM-S942N / Android 17**에서 화면 제어, 한/영·오른쪽 Shift,
전체·영역·미니바 캡처와 휴대폰 사본 일치, 취소, 미니바 조작, 창 크기 보정과
정상 종료 복원을 확인했습니다. 실기는 앞선 GUI 검토 빌드로 진행했으며,
최종 2.1.0은 버전 표시·문서·CI 패키징을 바꾼 것으로 전체 실기를 다시 했다고
기재하지 않습니다.

키보드에 F14가 없어 Enter 전환은 실기 미확인입니다. ADB 대체 입력·무선·복수 기기·
단일창 실기·외부 화면·다른 Galaxy·Intel/Galaxy 동작도 별도 확인 대상입니다.
캡처에는 Mac 창 제목 표시줄이 포함되며, 보안 잠금이나 접기로 DeX도 잠길 수 있습니다.
Windows 기능이 모두 동일한 것은 아닙니다. [대응 범위](https://github.com/asyouplz/DX-Manager-mac/blob/macos-v2.1.0/docs/MACOS_GUI_PARITY.md)를 확인하세요.

설정·로그는 앱 밖에 저장하며, 기존 포터블 폴더 설정을 자동으로 옮기지 않습니다.
Companion APK 포함·자동 설치 방식은 바꾸지 않았습니다. 기존 링크와 되돌리기를 위해
2.0.1·2.0.2 파일도 보존합니다. ZIP과 체크섬을 같은 폴더에 놓고 위 `shasum` 명령으로
`OK`를 확인하세요. Intel은 파일 이름의 `arm64`를 `x64`로 바꿉니다.
