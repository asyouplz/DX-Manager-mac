# DX Manager for macOS

DX Manager for macOS is distributed as a portable ZIP package. Extract the
complete archive and run it from the extracted folder. The package includes the
DX Manager runtime, scrcpy 4.1, ADB, and the scrcpy server. Homebrew and a
separate .NET installation are not required.

The portable packages require **macOS 14 Sonoma or later**.

## English

This guide describes the macOS 2.0.2 release. Its ZIP includes the optional
app launcher and terminal `O` help menu. The earlier `macos-v2.0.1` download
does not contain these additions.

### 1. Choose the correct package

- **Apple Silicon Mac:** choose the package labeled **arm64**. This applies to
  Macs with an Apple M-series chip.
- **Intel Mac:** choose the package labeled **x64** or **x86_64**.

If you are not sure which Mac you have, open the Apple menu and select **About
This Mac**. The window shows either an Apple chip or an Intel processor.

The two packages provide the same DX Manager functions. Only their processor
architecture is different.

### 2. Verify the downloaded ZIP

Keep the matching `.zip.sha256` file supplied with this ZIP beside it. Before
extracting, open Terminal in that folder and run:

```bash
release_version="<version>"
shasum -a 256 -c "DX-Manager-v${release_version}-macos-arm64.zip.sha256"
```

When reading this source document on GitHub, replace `<version>` with the
Release version shown in the downloaded filename, for example `2.0.2`. The
README inside a packaged ZIP already contains the exact package version.
For an Intel Mac, replace `arm64` with `x64`. Continue only when the command
prints `OK`. If it reports a mismatch, do not run the ZIP; download both files
again from the Release.

### 3. Extract and keep the complete folder

1. Extract the entire ZIP archive to a folder where your user account can write
   files, such as **Downloads** or **Documents**.
2. Keep all extracted files and subfolders together.
3. Do not move only `Start DX Manager.command` or only the DX Manager
   executable. The launcher uses the bundled runtime, scrcpy 4.1, ADB, and
   related files from this folder.

If the ZIP also includes **`DX Manager.app`**, you may move that complete app
to your Applications folder or another location independently. Do not move
individual files out of the app's contents.

### 4. Prepare the Galaxy phone

1. On the phone, open **Settings > About phone > Software information**.
2. Tap **Build number** seven times to enable Developer options.
3. Open **Settings > Developer options** and enable **USB debugging**.
4. Unlock the phone and connect it to the Mac with a USB cable that supports
   data transfer.
5. When the phone displays **Allow USB debugging?**, verify the computer and
   approve the RSA key. You may select **Always allow from this computer** if
   this is your Mac.

DX Manager cannot control a device shown as `unauthorized`. If the RSA prompt
does not appear, reconnect the cable while the phone is unlocked and check the
USB debugging setting again.

### 5. Start DX Manager

If **`DX Manager.app`** is included, open it in Finder. Otherwise, double-click
**`Start DX Manager.command`** in the extracted folder. Both launch the same
terminal dashboard. The app is a launcher for this interface, not a separate
graphical settings window.

Use the menu as follows:

- Press `1` to start DeX mode.
- Press `2` to stop the active DeX session and remove the virtual display.
- Press `S` to select a phone, then `9` to edit that phone's settings. Saved
  launch preferences apply to newly started windows.
- Press `O` in the dashboard to display phone-screen shortcut help. It does
  not change the screen state. Focus the intended DeX/scrcpy window, then
  press left `Option+O` for panel off or `Option+Shift+O` for on. The running
  scrcpy session handles these shortcuts directly.
- Press `Q` to exit DX Manager.

Panel-off is different from locking the phone. These shortcuts do not dismiss
the lock screen. The power/lock button, folding, or a security lock may also
lock DeX. If DeX becomes black after locking, unlock the phone normally before
retrying; model and firmware behavior still needs verification.

The app's settings are stored in
`~/Library/Application Support/DX Manager/config/settings.json`, and its logs
in `~/Library/Logs/DX Manager`. The portable launcher keeps using its own
folder's `config` and `logs`. The two settings locations are separate; launching
the app does not automatically import or overwrite your portable settings.

Keep the phone connected while starting or stopping the session. Selecting `Q`
also stops active DX Manager windows and requests removal of the DeX virtual
display. Wait for the final cleanup message before disconnecting the cable. If
the message says that a cleanup step could not be confirmed, reconnect the
phone and use `2` before exiting again.

### 6. First launch and Gatekeeper

This package is not currently signed with an Apple Developer ID or notarized by
Apple. On the first launch, macOS may block the launcher or display a warning.

After verifying the download, attempt to open the app or launcher once. If
macOS blocks it, open **System Settings > Privacy & Security** and use
**Open Anyway** for that item if offered. On macOS 15 and later, Control-click
does not override Gatekeeper. See [Apple's opening instructions](https://support.apple.com/en-us/102445)
and [macOS 15 change notice](https://developer.apple.com/news/?id=saqachfa).

The optional app uses ad hoc signing, which is not Developer ID signing or
notarization. macOS may still ask you to approve embedded components. The
launcher does not remove quarantine attributes or change system security
settings.

The wording and location of these controls can differ by macOS version. Without
Apple Developer ID signing and notarization, a completely warning-free launch
on every supported Mac and macOS version cannot be guaranteed.

### Package contents and limits

- Bundled DX Manager runtime for the selected Mac architecture
- Bundled scrcpy 4.1, ADB, and scrcpy server
- No Homebrew requirement
- No separate .NET installation requirement
- No DX Companion APK in the current macOS package

Physical-device testing used `2.0.2-preview.2` on an Apple Silicon Mac with a
USB-connected SM-S942N (Android 17 / SDK 37 / One UI property `90000`). DeX
startup, native screen-on/off shortcuts, help-only `O`, and normal stop/exit
restoration were confirmed. Version 2.0.2 retains that runtime behavior;
its release-version metadata, archive, and signature checks are recorded
separately in the release notes, not as another physical-device test.

Intel/Rosetta execution, other models or firmware, folding/manual locking,
visual Finder launch, and first launch from a quarantined download remain
unverified for this revision. Package and architecture checks alone do not
verify those workflows.

Do not add, replace, or delete bundled ADB and scrcpy files unless the package
instructions for a later version explicitly require it.

---

## 한국어

이 안내는 macOS 2.0.2 릴리스 기준입니다. ZIP에는 선택형 `.app` 실행기와
터미널 `O` 도움말 메뉴가 포함됩니다. 이전 `macos-v2.0.1` 다운로드에는
이 기능이 들어 있지 않습니다.

DX Manager macOS 버전은 포터블 ZIP 패키지로 배포됩니다. ZIP 전체를 풀고
압축을 푼 폴더에서 실행하십시오. 패키지에는 DX Manager 런타임, scrcpy 4.1,
ADB와 scrcpy 서버가 포함됩니다. Homebrew와 별도의 .NET 설치는 필요하지
않습니다.

포터블 패키지의 최소 운영체제는 **macOS 14 Sonoma**입니다.

### 1. Mac에 맞는 패키지 선택

- **Apple Silicon Mac:** **arm64**로 표시된 패키지를 선택하십시오. Apple M
  시리즈 칩이 탑재된 Mac이 여기에 해당합니다.
- **Intel Mac:** **x64** 또는 **x86_64**로 표시된 패키지를 선택하십시오.

Mac의 종류를 모르면 Apple 메뉴에서 **이 Mac에 관하여**를 여십시오. 이 화면에
Apple 칩 또는 Intel 프로세서가 표시됩니다.

두 패키지의 DX Manager 기능은 같습니다. 프로세서 아키텍처만 다릅니다.

### 2. 다운로드한 ZIP 확인

ZIP과 함께 제공된 같은 이름의 `.zip.sha256` 파일을 ZIP 옆에 둡니다.
압축을 풀기 전에 해당 폴더에서 터미널을 열고 다음 명령을
실행하십시오.

```bash
release_version="<version>"
shasum -a 256 -c "DX-Manager-v${release_version}-macos-arm64.zip.sha256"
```

이 원본 문서를 GitHub에서 읽는 경우 `<version>`을 내려받은 파일명에 표시된
Release 버전(예: `2.0.2`)으로 바꾸십시오. 패키지 ZIP 안의 README에는 실제
패키지 버전이 이미 반영됩니다.
Intel Mac에서는 `arm64`를 `x64`로 바꿉니다. 결과에 `OK`가 표시된 경우에만
계속하십시오. 불일치가 표시되면 실행하지 말고 Release에서 두 파일을 다시
내려받으십시오.

### 3. ZIP 전체 압축 해제 및 폴더 유지

1. ZIP 전체를 **다운로드** 또는 **문서**처럼 사용자 계정이 파일을 쓸 수
   있는 폴더에 압축 해제하십시오.
2. 압축을 푼 모든 파일과 하위 폴더를 한 폴더 안에 그대로 유지하십시오.
3. `Start DX Manager.command` 또는 DX Manager 실행 파일만 따로 옮기지
   마십시오. 실행기는 같은 폴더에 포함된 런타임, scrcpy 4.1, ADB와 관련
   파일을 사용합니다.

ZIP에 **`DX Manager.app`**도 포함되어 있다면 `.app` 전체를 응용 프로그램 폴더
등으로 따로 옮길 수 있습니다. 앱 내부의 개별 파일만 꺼내 옮기지는 마십시오.

### 4. Galaxy 휴대폰 준비

1. 휴대폰에서 **설정 > 휴대전화 정보 > 소프트웨어 정보**를 여십시오.
2. **빌드번호**를 일곱 번 눌러 개발자 옵션을 활성화하십시오.
3. **설정 > 개발자 옵션**에서 **USB 디버깅**을 켜십시오.
4. 휴대폰 잠금을 해제하고 데이터 전송을 지원하는 USB 케이블로 Mac과
   연결하십시오.
5. 휴대폰에 **USB 디버깅을 허용하시겠습니까?**가 표시되면 연결된 컴퓨터를
   확인한 뒤 RSA 키를 승인하십시오. 본인의 Mac이면 **이 컴퓨터에서 항상
   허용**을 선택할 수 있습니다.

장치 상태가 `unauthorized`이면 DX Manager에서 장치를 제어할 수 없습니다.
RSA 승인 화면이 나타나지 않으면 휴대폰 잠금이 해제된 상태에서 케이블을 다시
연결하고 USB 디버깅 설정을 확인하십시오.

### 5. DX Manager 시작

**`DX Manager.app`**이 포함되어 있으면 Finder에서 여십시오. 없으면 압축을 푼
폴더의 **`Start DX Manager.command`**를 더블클릭합니다. 두 실행기 모두 같은
터미널 대시보드를 엽니다. `.app`은 기존 화면의 실행기이며 별도의 그래픽 설정
창을 제공하는 것은 아닙니다.

메뉴는 다음과 같이 사용합니다.

- `1`: DeX 모드를 시작합니다.
- `2`: 실행 중인 DeX 세션을 중지하고 가상 디스플레이를 제거합니다.
- `S`로 휴대폰을 선택한 뒤 `9`에서 해당 기기의 설정을 수정합니다. 저장한
  시작 옵션은 새로 여는 창에 적용합니다.
- 대시보드의 `O`는 화면 제어 단축키 안내만 표시하며 화면 상태를 바꾸지 않습니다.
  대상 DeX/scrcpy 창에 포커스를 둔 뒤 왼쪽 `Option+O`로 패널을 끄고
  `Option+Shift+O`로 켭니다. 실행 중인 scrcpy 세션이 단축키를 직접 처리합니다.
- `Q`: DX Manager를 종료합니다.

패널 끄기와 휴대폰 잠금은 다릅니다. 이 단축키는 잠금 화면을 해제하지 않습니다.
전원·잠금 버튼, 접기 또는 보안 잠금으로 DeX도 잠길 수 있습니다. 휴대폰 잠금 후
DeX가 검게 되면 정상적으로 잠금을 해제한 뒤 다시 확인하십시오. 모델과 펌웨어에
따른 동작은 별도로 확인해야 합니다.

`.app` 설정은 `~/Library/Application Support/DX Manager/config/settings.json`,
로그는 `~/Library/Logs/DX Manager`에 저장합니다. 포터블 실행기는 계속 자기
폴더의 `config`와 `logs`를 사용합니다. 두 설정 위치는 별개이며 `.app`을 열어도
기존 포터블 설정을 자동으로 가져오거나 덮어쓰지 않습니다.

세션을 시작하거나 중지하는 동안에는 휴대폰 연결을 유지하십시오. `Q`를
선택해도 DX Manager가 실행한 창을 중지하고 DeX 가상 디스플레이 제거를
요청합니다. 마지막 정리 완료 메시지를 확인한 뒤 케이블을 분리하십시오. 일부
정리 단계를 확인하지 못했다는 메시지가 나오면 휴대폰을 다시 연결하고 `2`로
중지한 뒤 다시 종료하십시오.

### 6. 최초 실행 및 Gatekeeper

현재 패키지는 Apple Developer ID 서명과 공증이 적용되지 않은 빌드입니다. 최초
실행 시 macOS가 실행을 차단하거나 경고를 표시할 수 있습니다.

다운로드 검증 후 앱이나 실행기를 한 번 엽니다. macOS가 실행을 차단하면
**시스템 설정 > 개인정보 보호 및 보안**에서 해당 항목의 **그래도 열기**를
사용합니다. macOS 15 이상에서 Control-클릭은 Gatekeeper
승인 방법이 아닙니다. [Apple 실행 안내](https://support.apple.com/en-us/102445)와
[macOS 15 변경 안내](https://developer.apple.com/news/?id=saqachfa)를 참조하십시오.

선택형 `.app`의 ad hoc 서명은 Developer ID 서명이나 공증을 대신하지 않습니다.
내부 구성요소의 승인이 추가로 필요할 수 있습니다. 실행기는 quarantine 속성을
삭제하거나 시스템 보안 설정을 바꾸지 않습니다.

macOS 버전에 따라 메뉴 문구와 위치가 다를 수 있습니다. Apple Developer ID
서명과 공증이 없으면 지원 대상의 모든 Mac과 macOS 버전에서 경고가 전혀 없는
실행을 보장할 수 없습니다.

### 패키지 구성 및 범위

- 선택한 Mac 아키텍처용 DX Manager 런타임
- 번들 scrcpy 4.1, ADB와 scrcpy 서버
- Homebrew 설치 불필요
- 별도 .NET 설치 불필요
- 현재 macOS 패키지에는 DX Companion APK가 포함되지 않음

실기 검증은 Apple Silicon Mac과 USB로 연결한 SM-S942N(Android 17 / SDK 37 /
One UI 속성값 `90000`)에서 `2.0.2-preview.2`로 수행했습니다. DeX 시작,
기본 화면 켜기·끄기 단축키, 안내만 표시하는 `O`, 정상 중지·종료 시 복원을
확인했습니다. 2.0.2는 이 실행 동작을 유지하며, 최종 릴리스 버전 표기·압축파일·
서명 검사는 릴리스 설명에 별도로 기록합니다. 이를 추가 실기 검증으로 보지는
않습니다.

이번 수정의 Intel/Rosetta 실행, 다른 모델·펌웨어, 접기·수동 잠금, Finder 화면을
통한 실행과 다운로드 격리 속성이 있는 파일의 첫 실행은 아직 확인하지
않았습니다. 패키지와 아키텍처 검사만으로 해당 흐름이 검증된 것은 아닙니다.

이후 버전의 패키지 안내에서 명시적으로 요구하지 않는 한 번들 ADB와 scrcpy
파일을 추가, 교체 또는 삭제하지 마십시오.
