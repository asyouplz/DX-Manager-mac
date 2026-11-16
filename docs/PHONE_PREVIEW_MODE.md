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

### Stay awake (unreleased change)

In hidden-preview (loopback / native DeX) mode, the host now adds the fixed
`keep-active` argument to DXLoopback when the per-device **Stay awake** option
is on. After READY, while its lease is alive, the helper signals user activity
for the phone's default display about every 4 seconds through the hidden
`IPowerManager.userActivity(displayId 0, uptime, EVENT_OTHER, USER_ACTIVITY_FLAG_NO_CHANGE_LIGHTS)`.
The activity stops on STOP, 15 s heartbeat expiry, or ownership loss. It writes
no Android settings, holds no wakelock, never calls wakeUp/goToSleep/keyguard/
display-power APIs, and needs nothing restored. With stay-awake off, the helper
command line is unchanged; device behavior with it off is untested.

If the call is unavailable, the helper prints
`DXM_LOOPBACK_WARN keep_active_unavailable` once, the host logs a warning, and
the DeX session continues. This WARN path has not been tested on a real device.

The root cause is source-verified and device-observed: scrcpy `--keep-active`
(4.1 and 5.0.1) signals activity only for its own target display. On the test
phone, Samsung loopback DeX used power/display group 2, separate from built-in
display group 0, so it did not refresh the phone's own screen timeout.
`stay_on_while_plugged_in=7` is Windows-only and works only while charging.
The Mac app never sets it; before this change, hidden-preview DeX on Mac relied
on scrcpy `--keep-active` alone for both USB and wireless.

This tree is the released v2.2.0 line. Shipping the new helper requires a new
version/package, which has not been prepared, signed, notarized or published.
The local test package under git-ignored `dist/local-keep-active-test/` is not a
release. See [implementation notes](TECH_NOTES.md) and the
[reported automated results](SESSION.md#2026-11-16--loopback-keep-active-documentation-unreleased).

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
  the Mac edition has no shared power-priority service. With the unreleased
  helper change, a hidden-DeX session with stay-awake on keeps the phone itself
  from timing out, so its screen can stay on (possibly dimmed) for the whole
  session. Whether the panel dims, and battery and heat impact, are untested.
  Manual locking is not prevented by design; manual lock during a keep-active
  session is untested.
- Turning the phone panel fully off while DeX stays alive, PC/Mac audio volume
  control, and upstream Windows v3.0.0 (NativeDex helper) are out of scope and
  were not done.

### Acceptance — app path and remaining items untested

Every Unverified row below is an untested item, not a known-working claim or a
confirmed bug. The direct-ADB observations below do not verify the app path.

| Scenario | Required observation | Status |
| --- | --- | --- |
| Apple Silicon / Intel Mac | DeX appears in the Mac window | Unverified |
| Hidden mode on | Phone home/apps usable without preview | Unverified |
| Hidden mode off | Overlay mode and saved resolution/DPI return | Unverified |
| USB / wireless disconnect | Phone ends DeX, nominally within about 15 s | Unverified |
| Stop / Command+Q / force quit | Only the owned DeX session ends | Unverified |
| 1. Smart Stay isolation | Smart Stay off; > 120 s idle with no other activity while the phone stays awake | Unverified |
| 2. Old-behavior lock | Keyguard appears and the DeX window locks on this phone | Unverified |
| 3. Originally reported scenario | Wireless (Wi-Fi) ADB on battery | Unverified |
| 4. Real DX Manager path | Windows app and Mac app launch the helper with the flag, end to end | Unverified |
| 5. Windows validation | net462 x64 Release build, `DexManager.MultiDeviceTests` on Windows, Windows 7 SP1 / Windows 11, any device run | Unverified |
| 6. Session and panel behavior | Manual lock (power button / DeX menu), folding, long sessions, battery and heat with panel on or dimmed, whether the panel dims | Unverified |
| 7. Stay-awake off / lease expiry | Stay-awake off on a device; normal timeout after disconnect / host crash (expected within 15 s lease expiry, not measured) | Unverified |
| 8. Concurrent sessions | Two or more phones; DeX plus single-window sessions on the same phone | Unverified |
| 9. Compatibility | Other Galaxy models, Android / One UI versions, phones with Smart Stay off | Unverified |
| 10. Unavailable hidden call | WARN path on firmware where the call is missing or rejected | Unverified |

### 2026-11-16 (Asia/Seoul) — one-phone direct-ADB observation

This is a single-phone record supplied by the orchestrating agent, not a DX
Manager app test on either platform. The agent started the helper directly
over ADB from a Mac and attached Homebrew scrcpy 4.1 with
`--display-id <id> --keep-active --no-audio`.

- Phone: Galaxy SM-S942N, Android 17 (SDK 37), One UI 9.0; screen timeout 120 s,
  `stay_on_while_plugged_in=0`, Samsung Smart Stay ("keep screen on while viewing")
  on; USB ADB while charging.
- Across four sessions, DeX reported `displayGroupId 2`, the built-in display
  used group 0, and scrcpy's user-activity calls were logged for DeX only.
- Old behavior, without helper keep-active: one session of about 4 min. The
  built-in power group slept about 120 s after its last activity while DeX's
  group stayed awake. Keyguard appearing and the DeX window locking were not
  observed within the approximately 30 s that followed; both remain untested.
- New behavior, with helper keep-active: three sessions totaling about 14 min.
  Helper NO_CHANGE_LIGHTS calls were logged for display 0 at spacing no greater
  than about 4 s, and the built-in group never slept. However, Smart Stay face
  detection also reset the activity timer at roughly 100 s in every cycle,
  even with the front camera covered. No interval longer than the 120 s timeout
  without other activity was produced; the fix was not isolated from Smart Stay.
- A session started while the phone was already asleep/locked did not wake or
  unlock it; the helper's calls were ignored until the user unlocked the phone.
- After each session, no helper jar and no Wi-Fi display remained on the phone.

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
정리 시작 기준입니다.

### 잠자기 방지 (미출시 변경)

휴대폰 미리보기 숨김(loopback / native DeX) 모드에서 기기별 **잠자기 방지**가
켜져 있으면 호스트가 DXLoopback 실행 인자에 고정된 `keep-active`를 추가합니다.
READY 이후 lease가 유효한 동안 약 4초마다 숨겨진
`IPowerManager.userActivity(displayId 0, uptime, EVENT_OTHER, USER_ACTIVITY_FLAG_NO_CHANGE_LIGHTS)`로
휴대폰 기본 디스플레이의 사용자 활동을 알립니다. STOP, 15초 heartbeat 만료 또는
소유권 상실 시 활동 알림을 중지합니다. Android 설정을 쓰거나 wakelock을 잡지 않고,
wakeUp/goToSleep/keyguard/display-power API를 호출하지 않으며 복원할 상태도
없습니다. 잠자기 방지를 끄면 helper 명령행은 기존과 같지만, 꺼진 상태의 실기
동작은 미확인입니다.

호출을 사용할 수 없으면 helper가 `DXM_LOOPBACK_WARN keep_active_unavailable`을
한 번 출력하고 호스트는 경고를 기록하며 DeX 세션은 계속됩니다. 실제 기기에서 이
WARN 경로는 미확인입니다.

원인은 소스 확인과 기기 관찰에 근거합니다. scrcpy 4.1·5.0.1의 `--keep-active`는
자신의 대상 디스플레이에만 사용자 활동을 알립니다. 시험한 휴대폰에서는 삼성
loopback DeX가 전원·디스플레이 그룹 2, 내장 디스플레이가 그룹 0으로 분리되어
휴대폰 자체의 화면 timeout이 갱신되지 않았습니다. Windows에서만 사용하는
`stay_on_while_plugged_in=7`은 충전 중에만 동작합니다. Mac 앱은 이 값을 설정하지
않으므로 변경 전 Mac의 숨김 DeX는 USB·무선 모두 scrcpy `--keep-active`에만
의존했습니다.

이 트리는 공개된 v2.2.0 계열이며 새 helper를 배포하려면 새 버전·패키지가
필요합니다. 해당 릴리스는 준비·서명·공증·게시하지 않았습니다. Git에서 제외된
`dist/local-keep-active-test/`의 로컬 시험 패키지는 릴리스가 아닙니다.
구현은 [TECH_NOTES](TECH_NOTES.md), 전달받은 자동 검증 결과는
[SESSION](SESSION.md#2026-11-16--loopback-keep-active-documentation-unreleased)에 기록합니다.

### 제약

Windows 판의 다른 창 화면 끄기 우선순위 조정은 Mac에 해당 공용 서비스가 없어
옮기지 않았습니다. 미출시 helper 변경에서 숨김 DeX와 잠자기 방지가 켜져 있으면
휴대폰 자체의 timeout을 막으므로 세션 내내 화면이 켜져 있거나 어두워진 채 남을 수
있습니다. 패널이 실제로 어두워지는지와 배터리·발열 영향은 미확인입니다. 설계상
수동 잠금을 막지 않으며, keep-active 세션 도중 수동 잠금 실기는 미확인입니다.
DeX를 유지하면서 휴대폰 패널을 완전히 끄기, PC/Mac 오디오 볼륨 제어,
upstream Windows v3.0.0(NativeDex helper)은 범위 밖이며 수행하지 않았습니다.

### 수용 검증 — 앱 경로와 남은 항목은 미확인

아래 미확인 항목은 아직 시험하지 않은 항목이며 정상 동작이나 확인된 버그를
뜻하지 않습니다. 직접 ADB 관찰은 앱 경로 검증을 대신하지 않습니다.

| 시나리오 | 확인할 내용 | 상태 |
| --- | --- | --- |
| Apple Silicon / Intel Mac | Mac 창에 DeX 표시 | 미확인 |
| 숨김 모드 켜짐 | 미리보기 없이 휴대폰 홈·앱 사용 | 미확인 |
| 숨김 모드 꺼짐 | overlay와 저장한 해상도·DPI 복귀 | 미확인 |
| USB / 무선 연결 해제 | 휴대폰 DeX 종료, 약 15초는 명목 기준 | 미확인 |
| 중지 / Command+Q / 강제 종료 | 소유한 DeX 세션만 종료 | 미확인 |
| 1. Smart Stay 영향 분리 | Smart Stay를 끄고 다른 활동 없이 120초 넘게 유휴 상태에서도 휴대폰이 깨어 있는지 | 미확인 |
| 2. 이전 동작의 잠금 | 이 휴대폰에서 keyguard 표시와 DeX 창 잠금 | 미확인 |
| 3. 최초 보고 환경 | 배터리 상태의 무선(Wi-Fi) ADB | 미확인 |
| 4. 실제 DX Manager 경로 | Windows·Mac 앱이 인자를 전달해 helper를 시작하는 전체 경로 | 미확인 |
| 5. Windows 검증 | net462 x64 Release 빌드, Windows의 `DexManager.MultiDeviceTests`, Windows 7 SP1 / Windows 11, 모든 기기 실행 | 미확인 |
| 6. 세션·패널 동작 | 수동 잠금(전원 버튼 / DeX 메뉴), 접기, 장시간 세션, 패널이 켜지거나 어두워진 상태의 배터리·발열, 실제 어두워짐 여부 | 미확인 |
| 7. 잠자기 방지 끔 / lease 만료 | 옵션을 끈 실기, 연결 해제·호스트 비정상 종료 후 일반 timeout 복귀(15초 lease 만료 이내 예상, 미측정) | 미확인 |
| 8. 동시 세션 | 휴대폰 두 대 이상, 같은 휴대폰의 DeX·단일창 동시 실행 | 미확인 |
| 9. 호환성 | 다른 Galaxy 모델·Android / One UI 버전, Smart Stay를 끈 휴대폰 | 미확인 |
| 10. 숨겨진 호출 불가 | 호출이 없거나 거부되는 펌웨어의 WARN 경로 | 미확인 |

### 2026-11-16 (Asia/Seoul) — 휴대폰 한 대의 직접 ADB 관찰

오케스트레이션 에이전트가 전달한 단일 휴대폰 관찰이며, 어느 플랫폼에서도 DX
Manager 앱으로 실행한 시험이 아닙니다. Mac에서 ADB로 helper를 직접 시작하고
Homebrew scrcpy 4.1을 `--display-id <id> --keep-active --no-audio`로 연결했습니다.

- Galaxy SM-S942N, Android 17(SDK 37), One UI 9.0, 화면 timeout 120초,
  `stay_on_while_plugged_in=0`, Samsung Smart Stay("사용 중일 때 화면을 켠 채로 유지")
  켜짐, 충전 중인 USB ADB 환경입니다.
- 네 세션에서 DeX는 `displayGroupId 2`, 내장 디스플레이는 그룹 0이었고,
  scrcpy의 사용자 활동 호출은 DeX 디스플레이에만 기록되었습니다.
- 이전 동작(helper keep-active 없음) 한 세션 약 4분: 마지막 활동 약 120초 후
  내장 전원 그룹은 잠들었고 DeX 그룹은 깨어 있었습니다. 이후 약 30초 동안
  keyguard 표시와 DeX 창 잠금은 관찰되지 않았으며 두 항목은 미확인으로 남깁니다.
- 새 동작(helper keep-active 사용) 세 세션 합계 약 14분: display 0의
  NO_CHANGE_LIGHTS 호출 간격은 약 4초 이하였고 내장 그룹은 잠들지 않았습니다.
  다만 전면 카메라를 가려도 Smart Stay 얼굴 감지가 매 주기 약 100초에 활동
  타이머를 다시 갱신했습니다. 다른 활동 없이 timeout 120초를 넘긴 구간은 없어
  Smart Stay와 분리된 수정 효과는 확인하지 못했습니다.
- 이미 잠들고 잠긴 상태에서 시작한 세션은 휴대폰을 깨우거나 잠금을 풀지
  않았습니다. 사용자가 잠금을 풀기 전까지 helper 호출은 무시되었습니다.
- 각 세션 후 휴대폰에 helper jar와 Wi-Fi 디스플레이가 남지 않았습니다.
