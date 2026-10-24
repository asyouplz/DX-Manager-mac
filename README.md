<p align="center">
  <img src="DexManager/Resources/DXManager_256.png" width="112" alt="DX Manager">
</p>

<h1 align="center">DX Manager</h1>

<p align="center">Samsung DeX and independent Android app windows on Windows.</p>
<p align="center">Windows에서 Samsung DeX와 앱별 단일창을 관리합니다.</p>
<p align="center">
  <a href="#english">English</a> · <a href="#korean">한국어</a> ·
  <a href="https://github.com/maze-mei/DX-Manager/releases/latest">Downloads</a> ·
  <a href="docs/USER_GUIDE_EN.md">User guide</a> · <a href="docs/USER_GUIDE_KO.md">사용 설명서</a> ·
  <a href="docs/FAQ_EN.md">FAQ</a> · <a href="docs/FAQ_KO.md">자주 묻는 질문</a>
</p>

<!-- Replace with verified portable2.5.0 captures before publication. See docs/SCREENSHOT_PLAN_v2.5.0.md. -->

<a id="english"></a>

## English

### What it does

DX Manager is an independent Windows utility built around [scrcpy](https://github.com/Genymobile/scrcpy)
and ADB. It creates and tracks a Samsung DeX virtual display and can open up to three additional
single-app windows per connected Galaxy phone. Multiple phones keep independent sessions and settings.

The project began as personal Batch/CMD and AutoHotkey tools, then became a C# Windows application.
It is intended for day-to-day DeX use, including Windows 7 and PCs without Internet access.

### DX Manager 2.5.0 for Windows

| Component | Included version / requirement |
| --- | --- |
| DX Manager | 2.5.0, portable Windows x64 |
| Windows | 7 SP1, 8.1, 10 or 11; 32-bit Windows is not supported |
| Runtime | .NET Framework 4.6.2 or later |
| scrcpy | 5.0.1, automatic hardware-decoder selection |
| Optional DX Companion | Official 2.1.6/code13, Android 13 or later |

DeX testing includes Android 16/One UI 8.x, and the maintainer has reported Galaxy S26 Ultra /
Android 17 / One UI 9 operation. Older Classic DeX firmware may show a black DeX window;
single-window mode can be an alternative. Device, firmware and app restrictions still apply.
The optional Companion's Android 13 minimum is separate from the Windows application's requirements.

### Main features

- DeX plus three separately configured single-app windows for each phone.
- USB, USB-prepared wireless ADB and six-digit-code Android wireless debugging pairing.
- One entry per physical phone, with USB/Wi-Fi/both connection badges.
- Authorized USB takes priority for new launches when both connections exist; running sessions retain
  the transport they started with. Disconnecting USB does not silently move its windows to Wi-Fi.
- Per-phone resolution, DPI, bitrate, FPS, start apps and saved single-window app profiles.
- Experimental maximum 120 FPS, with confirmation before every start and automatic restoration of the prior screen-off preference. Default: 60 FPS.
- Unicode file/folder transfers in both directions, collision-safe names and independent transfer windows.
- HID keyboard/mouse, optional keyboard corrections, F8 capture and per-window mini control bars.
- Light/dark themes, embedded offline help, diagnostics and first-run consent saved after acceptance.
- Daily background update checks with an offline deadline, plus manual checking under Settings > About.
- Reopen the existing main window by running the EXE again. Hiding to tray closes attached manager
  dialogs while the managed Android sessions can continue.

### Download and start

1. Open [Releases](https://github.com/maze-mei/DX-Manager/releases/latest) and download the Windows ZIP
   matching the release, for example `DX-Manager-v2.5.0-win-x64.zip`.
2. Extract the entire archive to a writable folder. Run `DXManager.exe` with the adjacent files intact.
3. On first launch, read the notice, check the acknowledgement box and select **Confirm and start**.
   Accepting once is remembered; resetting application settings does not erase that acknowledgement.
4. Enable Developer options and USB debugging on the phone, connect it and approve the RSA prompt.
5. Choose the phone, select **DeX** and start. For a single window, select its slot and a start app first.
6. Open **Help and troubleshooting** in the app for offline instructions and recovery steps.

Windows 7 SP1 may need [.NET Framework 4.6.2](https://dotnet.microsoft.com/en-us/download/dotnet-framework/net462)
and the updates required by the bundled legacy ADB. A later installed .NET Framework 4.x runtime
satisfies the framework requirement. Internet is not required for local USB/LAN use once setup is complete.

Keep the phone connected until **Stop DeX** or tray **Exit** finishes cleanup.
The main window's X hides it to tray; **Left Alt+F8** or tray **Exit** terminates the application.
If an interrupted connection leaves a display or Stay awake setting behind, use the recovery steps
in [FAQ Q1](docs/FAQ_EN.md#q1-a-small-screen-secondary-display-remains-on-the-phone).

### Optional DX Companion

The ZIP includes `tools/companion/DX-Companion.apk`. It is not installed automatically.
Use **Settings > Companion**, choose the authorized target phone, then install/update and grant cleanup
permission. The official package, version, APK hash and signing certificate are checked.
**Update existing Companion installations to 2.1.6** for this release's notification cleanup behavior.

Companion provides recovery controls, a Quick Settings tile/widget and phone-to-PC file/folder sharing.
PC-to-phone drops are configured under **Settings > Paths > PC → phone file transfer**;
the reverse direction uses **Phone → PC file transfer > PC receive folder**.
It uses authenticated local communication with DX Manager, with no cloud file-transfer service.

A **DX Manager session protection** notification can appear as soon as DX Manager connects to the phone,
even before DeX starts. In 2.1.6, if the PC link is lost and both recovery settings are verified inactive,
the protection service stops without waiting for the configured recovery delay. Remaining recovery
work retains the existing disconnect policy. See [Companion notification FAQ](docs/FAQ_EN.md#q26-why-does-the-companion-session-protection-notification-remain).

### Updates

On the first launch of each local day, DX Manager checks for a newer stable GitHub release in the
background. An offline attempt is recorded for the day, with no automatic retry loop. Local operation
continues. **Settings > About > Check for updates** runs a manual check.

An automatic new-version notice is a nonmodal lower-right banner, or a tray notification while hidden.
No automatic latest-version/offline result dialog appears. The banner remains until X dismisses it;
its GitHub button opens the release page and leaves the banner visible. Updates are downloaded and
installed manually. A previously cached new-version banner can remain visible offline.

### Shortcuts and more help

| Action | Default shortcut |
| --- | --- |
| Enter capture mode / capture the active scrcpy client | F8 / F8 again |
| Cancel capture | Esc |
| Exit DX Manager | Left Alt+F8 |
| Optional Enter/Shift+Enter switching | Scroll Lock, when enabled under Settings > Input |
| scrcpy fullscreen /1:1 size | Alt+F or F11 / Alt+G |
| Phone screen off / on | Alt+O / Alt+Shift+O |

See the [user guide](docs/USER_GUIDE_EN.md), [FAQ](docs/FAQ_EN.md),
[2.5.0 release notes](docs/RELEASE_NOTES_v2.5.0.md) and
[verification record](docs/VERIFICATION_v2.5.0.md).

### Source, platforms and license

Windows source setup is documented in [Building](docs/BUILDING.md). The official Companion is maintained
as one shared component; a complete source build also needs that verified component.
The existing public repository's [macOS guide](https://github.com/maze-mei/DX-Manager/blob/main/docs/MACOS_GUIDE.md)
describes a separate platform port. This 2.5.0 Windows ZIP does not contain a Mac application.

DX Manager is MIT-licensed. scrcpy, its runtime libraries, Microsoft Fluent System Icons and the fonts
retain their own licenses; see [third-party notices](DexManager/licenses/THIRD_PARTY_NOTICES.md).
DX Manager is independently developed by [maze](https://github.com/maze-mei) and is not affiliated with,
sponsored by or endorsed by Samsung Electronics or Genymobile. Samsung and Samsung DeX are Samsung trademarks.
Questions and reports: [GitHub Issues](https://github.com/maze-mei/DX-Manager/issues).

---

<a id="korean"></a>

## 한국어

### 어떤 프로그램인가요?

DX Manager는 [scrcpy](https://github.com/Genymobile/scrcpy)와 ADB를 사용해 Samsung DeX 가상 화면과
휴대폰별 단일 앱 창을 최대 3개까지 관리하는 Windows 도구입니다. 여러 Galaxy 휴대폰의 세션과 설정을
서로 독립적으로 관리합니다. 개인용 Batch/CMD·AutoHotkey 도구에서 시작해 C# 프로그램으로 발전했으며,
Windows 7과 인터넷이 없는 PC에서도 일상적으로 사용할 수 있도록 만들었습니다.

### Windows용 2.5.0 구성

| 항목 | 포함 버전 / 요구 사항 |
| --- | --- |
| DX Manager | 2.5.0, Windows x64 포터블 |
| Windows | 7 SP1·8.1·10·11; 32비트 미지원 |
| 실행 환경 | .NET Framework 4.6.2 이상 |
| scrcpy | 5.0.1, 하드웨어 디코더 자동 선택 |
| 선택형 DX Companion | 공식2.1.6/code13, Android 13 이상 |

DeX 확인 기준은 Android 16/One UI 8.x이며, 개발자가 Galaxy S26 Ultra / Android 17 / One UI 9의 동작도
보고했습니다. 이전 Classic DeX 펌웨어에서는 DeX 창이 검게 표시될 수 있어 단일창 모드를 고려할 수
있습니다. 기기·펌웨어·앱별 제한은 남아 있으며, Companion의 Android 13 요구 사항은 PC 프로그램과 별도입니다.

### 주요 기능

- 휴대폰마다 DeX와 서로 다른 설정의 단일창 3개 실행.
- USB, USB로 준비하는 무선 ADB,6자리 코드로 연결하는 Android 무선 디버깅 페어링.
- 같은 휴대폰의 USB·Wi-Fi 연결 통합과 USB/무선/동시 연결 아이콘.
- 두 연결이 있으면 새 실행은 승인된 USB 우선. 실행 중인 창은 시작한 연결을 유지하며,
  USB를 뽑았다고 해당 창을 Wi-Fi로 자동 이전하지 않습니다.
- 기기별 해상도·DPI·비트레이트·FPS·시작 앱과 단일창 앱 프로필.
- 최대 120 FPS 실험적 옵션: 매 실행 전 경고, 이전 화면 끄기 값 복원. 기본값은 60 FPS입니다.
- 한글 등 Unicode 이름과 폴더 구조를 보존하는 양방향 파일 전송, 충돌 이름 분리와 독립 전송창.
- HID 키보드·마우스, 선택형 키 입력 보정, F8 캡처와 창별 미니 컨트롤바.
- 밝음·다크 테마, 앱 안의 오프라인 도움말, 진단과 최초 동의 기록 저장.
- 하루 한 번 백그라운드 업데이트 확인과 ‘설정 > 정보’의 수동 확인.
- EXE를 다시 실행하면 기존 메인창 복원. 메인을 트레이로 숨길 때 설정·도움말 등 부속 창은 닫힙니다.

### 다운로드와 시작

1. [릴리스](https://github.com/maze-mei/DX-Manager/releases/latest)에서 해당 버전의 Windows ZIP을 받습니다.
   파일 이름 예시는 `DX-Manager-v2.5.0-win-x64.zip`입니다.
2. 쓰기 가능한 폴더에 전체 압축을 풀고 옆 파일들을 유지한 채 `DXManager.exe`를 실행합니다.
3. 첫 실행 안내를 읽고 확인란을 선택한 뒤 **확인하고 시작**을 누릅니다. 동의 후에는 반복하지 않으며,
   설정 초기화로도 동의 기록이 지워지지 않습니다.
4. 휴대폰의 개발자 옵션·USB 디버깅을 켜고 연결한 뒤 RSA 허용 창을 승인합니다.
5. 대상 휴대폰과 **DeX**를 선택해 시작합니다. 단일창은 슬롯과 시작 앱을 먼저 선택해야 합니다.
6. 사용·복구 방법은 앱의 **도움말 · 문제 해결**에서 인터넷 없이 확인할 수 있습니다.

Windows 7 SP1에는 [.NET Framework 4.6.2](https://dotnet.microsoft.com/en-us/download/dotnet-framework/net462)와
레거시 ADB에 필요한 업데이트가 필요할 수 있습니다. 더 최신 .NET Framework 4.x가 설치돼 있으면
그대로 사용합니다. 초기 준비 후 로컬 USB/LAN 사용에는 인터넷 연결이 필요하지 않습니다.

연결을 끊기 전에 **DeX 중지** 또는 트레이의 **종료**로 정리가 끝날 때까지 기다리세요.
메인창의 X는 트레이로 숨기는 동작입니다. 완전히 종료하려면 **왼쪽 Alt+F8** 또는 트레이 **종료**를
사용합니다. 화면이나 절전모드 해제 설정이 남으면 [FAQ Q1](docs/FAQ_KO.md#q1-휴대폰에-작은-화면보조-디스플레이이-남아-있습니다)을 확인하세요.

### 선택형 DX Companion

ZIP에 `tools/companion/DX-Companion.apk`가 들어 있지만 자동 설치하지 않습니다.
**설정 > Companion**에서 승인된 대상 휴대폰을 선택해 설치/업데이트하고 정리 권한을 부여하세요.
공식 패키지·버전·APK 해시·서명을 검증합니다. **기존 앱도 이번 정식2.1.6으로 업데이트해야 합니다.**

Companion은 복구 버튼, 빠른 설정 타일·위젯과 휴대폰→PC 파일·폴더 공유를 제공합니다.
PC→휴대폰 드롭은 **설정 > 경로 > PC → 휴대폰 파일 전송**, 반대 방향은
**휴대폰 → PC 파일 전송 > PC 수신 폴더**에서 설정합니다. 인증된 로컬 통신을 사용하며 클라우드로
파일을 보내는 서비스는 포함하지 않습니다.

**DX Manager 세션 보호** 알림은 DeX 실행 전에도 PC와 연결되면 표시될 수 있습니다.
2.1.6은 PC 연결이 끊기고 가상화면·잠자기 방지가 모두 해제됐음을 확인하면 복구 대기시간 없이 감시를
종료합니다. 복구할 항목이 남으면 기존 연결 해제 정책을 유지합니다.
자세한 내용은 [Companion 알림 FAQ](docs/FAQ_KO.md#q26-companion의-세션-보호-알림이-남아-있습니다)를 확인하세요.

### 업데이트 알림

매일 첫 실행에 GitHub의 최신 정식 버전을 백그라운드에서 한 번 확인합니다. 오프라인 실패도 당일
시도로 기록하고 자동으로 반복 재시도하지 않습니다. 로컬 사용은 계속할 수 있습니다.
직접 확인하려면 **설정 > 정보 > 업데이트 확인**을 누르세요.

새 버전 자동 안내는 메인 오른쪽 아래 배너이며, 숨겨져 있으면 트레이 알림을 사용합니다.
최신 버전·오프라인 결과창은 자동으로 띄우지 않습니다. 배너는 X로 닫을 때까지 유지하며 GitHub 버튼은
페이지를 열고 배너는 남겨둡니다. 다운로드·설치는 직접 진행합니다. 전에 발견한 새 버전 배너는
오프라인에서도 남아 있을 수 있습니다.

### 단축키와 도움말

| 기능 | 기본 단축키 |
| --- | --- |
| 캡처 모드 진입 / 활성 scrcpy 영역 캡처 | F8 / F8 한 번 더 |
| 캡처 취소 | Esc |
| DX Manager 종료 | 왼쪽 Alt+F8 |
| 선택형 Enter/Shift+Enter 전환 | 설정 > 입력에서 켠 경우 Scroll Lock |
| scrcpy 전체 화면 /1:1 크기 | Alt+F 또는 F11 / Alt+G |
| 휴대폰 화면 끄기 / 켜기 | Alt+O / Alt+Shift+O |

[사용 설명서](docs/USER_GUIDE_KO.md), [자주 묻는 질문](docs/FAQ_KO.md),
[2.5.0 변경 사항](docs/RELEASE_NOTES_v2.5.0.md), [검증 기록](docs/VERIFICATION_v2.5.0.md)을 참고하세요.

### 소스·다른 플랫폼·라이선스

Windows 소스 준비는 [빌드 안내](docs/BUILDING.md)를 따릅니다. 정식 Companion은 한 곳의 공용
컴포넌트로 관리하며, 전체 소스 빌드에는 해당 검증된 컴포넌트도 필요합니다.
기존 공개 저장소의 [macOS 안내](https://github.com/maze-mei/DX-Manager/blob/main/docs/MACOS_GUIDE.md)는
별도 플랫폼 이식을 설명하며, 이번 Windows용 2.5.0 ZIP에 Mac 프로그램이 들어 있는 것은 아닙니다.

DX Manager는 MIT 라이선스이며 scrcpy·런타임·Microsoft Fluent System Icons·글꼴은 각 라이선스를
따릅니다. [제3자 라이선스](DexManager/licenses/THIRD_PARTY_NOTICES.md)를 확인하세요.
[maze](https://github.com/maze-mei)가 독립적으로 개발하며 Samsung Electronics·Genymobile과 제휴·후원·보증
관계가 없습니다. Samsung·Samsung DeX는 Samsung의 상표입니다.
문의와 제보는 [GitHub Issues](https://github.com/maze-mei/DX-Manager/issues)를 이용하세요.
