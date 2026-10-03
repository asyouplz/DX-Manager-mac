# Optional phone-preview-free DeX (Windows and macOS, experimental)

## English

This branch adds **Hide DeX preview (experimental)** to the Windows DeX launch
options and a `P` choice to the macOS terminal menu. Off is the default and keeps
the existing simulated-display workflow.
Stop DeX before changing the switch, then start it again. The choice is saved
separately for each physical phone. Single-app windows are unchanged.

On macOS, stop DeX with `2`, press `P` to switch between showing and hiding the
phone preview, then press `1` to start. Command-line launches also accept
`./DXManager.Mac --dex --hide-phone-preview` or `--dex --show-phone-preview`.
The macOS app remains a terminal menu, not a Windows-style graphical window.

When enabled, DX Manager runs a bundled, hash-checked Android helper through
the selected ADB transport. The helper asks Samsung's wireless DeX service to
connect to the phone's own `127.0.0.1` address and negotiates RTSP locally.
Existing scrcpy then displays the newly identified Wi-Fi display on the PC.
It does not create an `overlay_display_devices` preview on the phone. This is
not ordinary screen mirroring or scrcpy's generic `--new-display` desktop.

The helper is prebuilt in `tools/loopback/dxm-loopback.jar`. End users do not
need Java, an Android SDK, root, or an additional APK. The existing USB debugging
authorization is still required. No Companion install/permission behavior changes.
The implementation follows the loopback activation method in
[ScrcpyDeX](https://github.com/Aureliano021/ScrcpyDex); attribution, Apache 2.0
license, source, and reproducible build instructions are in `DXLoopback/`.

### Differences and limits

- Windows x64 and macOS arm64/x64 use the same helper and host protocol.
  Choose the prebuilt ZIP for the computer's operating system and CPU.
- Galaxy S26, Windows 7/8.1/10/11, macOS, and individual One UI releases have **not**
  been physically validated for this new mode. Compilation and protocol tests
  do not establish Samsung firmware compatibility. Hidden APIs can change.
- The phone remains available for normal use. The stored DeX "screen off"
  preference is ignored for this mode, not erased. Power-control overrides in
  additional scrcpy arguments are rejected. A separate single-app window can
  still request screen off, and the phone's own lock/timeout policy still applies.
- Samsung negotiates the display mode; overlay resolution/DPI controls are
  disabled and their stored values are retained for the original mode.
- An existing external display, wireless DeX, or simulated display must be
  stopped by its owner first. DX Manager does not disconnect it automatically.
- On unsupported firmware or timeout, the attempt fails with an explanation;
  it does not silently change back to overlay mode or edit global desktop flags.
- Stop/close ends only the matching session. EOF or a 15-second host-heartbeat
  timeout asks the helper to clean up its owned connection. This is a bounded
  best-effort recovery mechanism, not a guarantee against firmware or OS failure.
  If Samsung keeps a connection, use the phone's DeX/Smart View disconnect UI.
- The helper removes its own unique temporary JAR. If transfer succeeds but
  Android cannot start the helper, that temporary file may remain; the host
  does not send a new cleanup shell to a possibly reused device address.
- Local dummy wireless-display traffic may add work on the phone. Battery,
  heat, DRM playback, sleep/wake, HID input, and long-session behavior need
  device testing. No performance improvement is claimed.

### Required physical test before removing the experimental label

1. On each Windows/macOS target with an unlocked S26, leave the option off: existing DeX start,
   stop, screen-off, and overlay cleanup must remain unchanged.
2. Stop, enable the switch, and start: verify full Samsung DeX on the PC and
   the ordinary launcher/apps on the phone, with no simulated-display preview.
3. Verify mouse, keyboard, audio, file transfer, and a simultaneous single-app
   window; its separately configured screen-off behavior must be explicit.
4. Stop, close scrcpy directly, and close DX Manager separately. Check that
   DeX disconnects, the helper exits, and no unrelated display/process stops.
5. Disconnect/reconnect USB, kill the host, sleep/wake the computer, and switch
   transport. Wait at least 15 seconds for heartbeat expiry where necessary.
6. Test two phones, tab changes during startup, startup failure, an already
   active HDMI/wireless display, repeated starts/stops, and settings persistence.
7. Disable the switch after stopping and verify the original resolution/DPI
   and screen-off preference return. Record OS/CPU, model, Android, One UI,
   and the actual results; do not mark untested cases as passing.

## 한국어

Windows의 DeX 실행 옵션에 **휴대폰 DeX 숨기기 (실험)** 스위치를 추가하고,
macOS에는 같은 기능을 선택하는 `P` 메뉴를 제공합니다.
기본값은 꺼짐으로, 지금까지 사용하던 휴대폰 보조 화면 방식이 유지됩니다.
**DeX 중지 → 스위치 선택 → DeX 시작** 순서로 바꾸며 휴대폰별로 저장됩니다.
단일 앱 창에는 적용하지 않습니다.

맥에서는 **`2`로 중지 → `P`로 표시/숨김 선택 → `1`로 시작**합니다.
명령어로 실행할 때는 `./DXManager.Mac --dex --hide-phone-preview` 또는
`--dex --show-phone-preview`를 사용할 수 있습니다. 맥 실행 화면은 기존과 같은
터미널 메뉴이며 Windows와 같은 그래픽 창으로 바뀌는 것은 아닙니다.

켜면 번들 보조 프로그램이 휴대폰 내부의 `127.0.0.1`을 대상으로 삼성 무선
DeX 연결을 만들고, 기존 scrcpy가 그 DeX 화면을 PC에 표시합니다. 휴대폰의
`보조 디스플레이 시뮬레이션`을 만들지 않는 방식입니다. 단순 미러링이나
일반 Android 자유 창 모드로 바꾸는 기능은 아닙니다.

보조 프로그램은 미리 빌드한 `tools/loopback/dxm-loopback.jar`로 포함됩니다.
사용자가 Java/Android SDK를 설치하거나 APK를 추가로 설치할 필요는 없습니다.
기존처럼 USB 디버깅 연결 승인은 필요합니다. Companion 설치와 권한은 바꾸지
않습니다. 참고 프로젝트는 ScrcpyDeX이며 출처·라이선스·빌드 방법은
`DXLoopback/`에 함께 제공합니다.

### 사용 시 알아둘 점

- 이번 기능은 **Windows·macOS 실험 기능**입니다. Windows x64, Apple Silicon
  arm64, Intel Mac x64용으로 각각 미리 빌드한 포터블 ZIP을 사용합니다.
  갤럭시 S26 및 각 운영체제/One UI 조합에서의 실기 검증은 아직 필요하며,
  자동 테스트 통과가 실기 성공을 뜻하지 않습니다.
- 휴대폰을 일반 화면으로 사용하기 위해 이 모드의 `폰 화면 끄기`는 적용하지
  않습니다. 원래 선택은 지우지 않습니다. 별도로 실행한 단일창의 화면 끄기와
  휴대폰 자체 자동 잠금 설정은 별개입니다.
- 해상도는 삼성 DeX가 연결 과정에서 정합니다. 기존 해상도/DPI 입력은
  비활성화하지만 값을 보존하므로 기존 방식으로 돌아가면 다시 사용합니다.
- 다른 외부 화면·무선 DeX·기존 가상 화면이 실행 중이면 먼저 직접 종료해야
  합니다. 이 기능이 다른 연결을 대신 끊지는 않습니다.
- 지원되지 않는 펌웨어나 시간 초과이면 이유를 표시하고 중단합니다. 사용자가
  모르는 사이 기존 미리보기 방식으로 전환하거나 전역 데스크톱 설정을 바꾸지
  않습니다.
- 정상 중지 시 이 세션만 정리합니다. 연결이 끊기거나 PC 프로그램이 종료되면
  보조 프로그램이 입력 종료 또는 최대 15초의 생존 신호 만료를 감지해 정리를
  시도합니다. 펌웨어/운영체제 오류까지 복구를 보장하지는 않습니다. 연결이
  남으면 휴대폰의 DeX/Smart View 연결 해제 화면에서 종료합니다.
- 임시 JAR는 휴대폰 보조 프로그램이 자신의 파일만 삭제합니다. 전송 후 실행에
  실패하면 파일이 남을 수 있지만, 다른 휴대폰이 재사용할 수 있는 연결 주소에
  별도 삭제 명령을 보내지는 않습니다.
- 발열·배터리·오디오·보호 콘텐츠·절전 복귀·장시간 사용은 실기 확인이 필요합니다.

실기 확인은 위 목록의 기존 방식 비교, 숨김 모드, 각 종료 경로, 케이블 분리,
두 기기 격리, 설정 복원 순으로 수행하고 모델과 One UI 버전을 함께 기록합니다.
