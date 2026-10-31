# Hide the phone DeX preview (macOS, experimental)

## English

Ported to macOS 2.2.0 from the Windows implementation in
[maze-mei/DX-Manager#8](https://github.com/maze-mei/DX-Manager/pull/8).
The option keeps Samsung DeX in the Mac window while the phone stays on its
normal home screen without the simulated-display preview. It is off by default,
saved per physical phone, and can only be changed while DeX is stopped.

### Use

- **GUI:** select the phone, open **DeX**, stop DeX if it is running, check
  **Hide phone preview (experimental)**, then **Save settings** or **Start DeX**.
- **Terminal edition:** select the phone with `S`, open settings with `9`, and
  toggle item `8`.

To return to the overlay mode, stop DeX, clear the option and start again.

### How it works

The bundled helper `tools/loopback/dxm-loopback.jar` is checked against a
pinned SHA-256 before use, pushed to a session-specific path under
`/data/local/tmp`, and run with `app_process` over the selected absolute-path
ADB. The physical phone identity is rechecked before and after the transfer.
The helper requests Samsung wireless DeX to the phone's own `127.0.0.1`; scrcpy
still carries the Mac's video, audio and input over USB or wireless ADB. No root,
extra APK, Java install or Companion permission change is needed. The helper
requires Samsung Android 12/API 31 or newer and its internal APIs; those checks
do not prove compatibility. Method and attribution:
[ScrcpyDeX](https://github.com/Aureliano021/ScrcpyDex), Apache-2.0
(`DXLoopback/` holds the source and `scripts/Build-DexLoopback.sh` rebuilds it).

### Limits

- Samsung negotiates resolution and DPI. The GUI disables those fields and phone
  screen-off in this mode; saved values return when the option is cleared.
  scrcpy screen-power arguments (`-S`, `--turn-screen-off`, `--power-off-on-close`,
  `--no-power-on` and abbreviations) are rejected.
- An existing overlay, HDMI or wireless DeX display must be stopped by its owner
  first. Activation failure stops with an explanation; there is no silent
  fallback to the overlay mode.
- The Mac sends a session heartbeat every 3 seconds. Stop, channel EOF, or 15
  seconds without a heartbeat starts phone-side cleanup of only the helper's own
  DeX connection. 15 seconds is a trigger, not a guaranteed completion time.
- The Windows edition's cross-window screen-on priority is not ported because
  the Mac edition has no shared power-priority service; only the DeX session
  itself keeps the phone screen on.

### Physical acceptance (Mac) — not yet performed

| Scenario | Required observation | Status |
| --- | --- | --- |
| Apple Silicon / Intel Mac | DeX appears in the Mac window | Unverified |
| Hidden mode on | Phone home/apps usable without preview | Unverified |
| Hidden mode off | Overlay mode and saved resolution/DPI return | Unverified |
| USB / wireless disconnect | Phone ends DeX, nominally within about 15 s | Unverified |
| Stop / Command+Q / force quit | Only the owned DeX session ends | Unverified |

## 한국어

Windows 구현([maze-mei/DX-Manager#8](https://github.com/maze-mei/DX-Manager/pull/8))을
macOS 2.2.0으로 옮긴 실험 기능입니다. Mac 창에는 DeX를 유지하고 휴대폰에는 가상 화면
미리보기 없이 일반 홈 화면을 표시합니다. 기본값은 꺼짐이며 휴대폰별로 저장하고
DeX가 중지된 상태에서만 바꿀 수 있습니다.

- **GUI:** 휴대폰을 선택하고 **DeX**에서 실행 중이면 중지한 뒤 **휴대폰 미리보기
  숨김 (실험)**을 체크하고 **설정 저장** 또는 **DeX 시작**을 누릅니다.
- **터미널 버전:** `S`로 휴대폰을 선택하고 `9` 설정에서 `8`번을 전환합니다.

해시가 고정된 보조 파일을 세션별 경로로 전송해 `app_process`로 실행하며, 휴대폰
고유 식별값을 전송 전후로 다시 확인합니다. 휴대폰 내부 `127.0.0.1`로 삼성 무선 DeX를
요청하고 실제 화면·오디오·입력은 기존 scrcpy가 처리합니다. 해상도·DPI는 삼성이
협상하므로 GUI에서 해당 입력과 화면 끄기를 비활성화하고, 화면 전원 관련 scrcpy 인자는
거부합니다. 다른 오버레이·HDMI·무선 DeX가 있으면 시작을 거부합니다. 3초마다 신호를
보내며 중지·연결 종료·15초 신호 손실 시 자신이 만든 DeX 연결만 정리합니다. 15초는
정리 시작 기준입니다. Windows 판의 다른 창 화면 끄기 우선순위 조정은 Mac에 해당 공용
서비스가 없어 옮기지 않았습니다. 위 표의 Mac 실기 항목은 모두 미확인입니다.
