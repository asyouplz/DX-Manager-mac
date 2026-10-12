# macOS 2.1.0 GUI parity and upstream maintenance

## English

The GUI uses the original Windows navigation and run-settings model, implemented
with AppKit controls. `build/macos/GuiApp.m` owns presentation; `GuiProtocol` and
`InteractiveHost.Gui` adapt actions to existing C# services. The native executable
launches a persistent `DXManager.Mac --gui-host` child with private stdin/stdout pipes.
It never opens Terminal, a command file, a shell, or an HTTP server. Requests are
serialized; EOF cancels an in-flight DeX start and invokes cleanup. App data stays
outside the signed bundle. `DXM_GUI_DATA_HOME` is an explicit developer/test home
override, used only by the GUI host, never embedded in public packages.

| Windows surface | Mac implementation | Validation / difference |
| --- | --- | --- |
| Device tabs, physical identity | Device selector; identity-keyed runtime map | Registry/isolation tests; simultaneous phones need physical testing |
| DeX and three single-window modes | Same four mode buttons and core services | Hardware validation tracked below; distinct from terminal 2.0.2 tests |
| Resolution, DPI, bitrate, FPS | Text fields plus resolution presets | Windows width 320–4096, height 240–4096, DPI 120–640 limits |
| Screen off, stay awake, force stop, start app, advanced args | Native checkboxes / app combo / text | Saves and launches through the same device profile; reserved targets rejected |
| HID keyboard / mouse, flex display | Native checkboxes, scrcpy `-K` / `-M` / flex flag | USB SM-S942N UHID typing checked in isolated review; mouse/flex and other hardware unverified |
| App profiles | Per-device save/load/delete; apply saved profile when selecting an app | Mode/device persistence tests |
| USB, wireless preparation, connection, pairing | Native settings page, scoped wireless service calls | USB/wireless hardware verification deferred |
| Language / appearance | Korean, English, system; light/dark/system | Live language/theme changes and persistence verified in isolated native UI |
| Startup / hide | Login launch item, start minimized, selected-phone auto-start, minimize delay | Mac Dock replaces tray; auto-start once per selected device per app lifetime |
| Paths | Bundled ADB/scrcpy paths displayed; editable transfer folders | Portable bundle owns tool paths; no Windows executable chooser |
| File transfers | File chooser, existing ADB send, managed scrcpy drop option, Companion receive option | Physical transfers and collision/cancel UI parity remain unverified |
| Diagnostics / logs / Companion | Native pages and read-only text windows; explicit device install/grant/remove | Verified-APK checks retained; no APK distribution change |
| Global key conversion | Native event tap, only for the focused owned scrcpy process | Accessibility permission; right Option replaces Hangul key, F14 replaces Scroll Lock; right Command becomes left Command rather than Windows F24 |
| F8 capture | F8 selection, second press whole window, drag region, Esc/timeout cancel | Screen Recording permission; PNG saved on Mac, optional transfer to the captured session's phone |
| Attached mini control bar | Panel off/on, power, fullscreen, original size constrained to the current screen, capture, manager, collapse; left/right placement | Existing scrcpy session; resize then fit within usable Mac display; security lock can still lock DeX |

The GUI therefore matches the main control/settings workflow, not every Windows
platform integration. Keep this distinction in release descriptions. Do not call
the new GUI hardware-tested using the old 2.0.2 terminal tests.

Native GUI-only checks on Apple Silicon covered editing and saving DeX defaults,
separate single-window settings, dirty navigation, invalid resolution rejection,
live English/Korean and light/dark changes, all settings pages, a log window,
and quit/relaunch persistence. Run/save buttons stay visible while scrolling.
Login registration has not been exercised. The user subsequently authorized phone testing.
On USB SM-S942N / Android 17, the isolated review verified phone panel off/on,
right Option language switching, right Shift release, F8 whole/region captures and
mini-bar capture with matching phone copies, Esc/timeout cancellation, fullscreen,
collapse and manager opening. A reported resize overflow prompted Mac display-bound
fitting. That fix and final stop validation are recorded in `SESSION.md`. F14 is absent
on the tested keyboard, so Enter toggling is not physically verified. Automated
checks do not establish physical keyboard behavior.

### Updating from the original project

The source baseline is pinned in `scripts/upstream/macos-source-map.json` to
`2a1ec107450d8755e3691e9fa52aa086ed034e8d`, with 67 original-to-Core mappings.
This is a maintenance baseline, not the current GUI package version. To review an
upstream release, fetch it into a local ref and run:

```bash
git fetch https://github.com/maze-mei/DX-Manager.git main
python3 scripts/Check-Mac-Upstream.py --ref FETCH_HEAD
```

The read-only checker lists direct source changes, files needing Mac adaptation,
Windows UI changes needing GUI parity review, and newly added files. It never
fetches, overwrites working files, advances the baseline, or publishes a release.
Integrate the changes on a branch, preserve platform adapters and existing user
settings, update the parity table, build/test/package both architectures, and run
the required Galaxy tests. Advance the baseline only after reviewing integration.
Version the Mac package separately while recording its original-project baseline.
This does not promise automatic conflict-free merging or scheduled monitoring.

## 한국어

원작의 모드·설정 구성을 AppKit 버튼과 체크박스로 구현했습니다. 화면 코드는
`build/macos/GuiApp.m`, 화면과 실행 코드의 연결은 `GuiProtocol`과
`InteractiveHost.Gui`, 기기·DeX 처리는 기존 C# 공통 서비스가 담당합니다.
앱은 자식 실행 파일과 내부 파이프로 통신하며 Terminal·쉘·웹 서버를 열지 않습니다.
종료나 통신 단절 시 시작 작업을 취소하고 이 앱이 만든 세션 정리를 수행합니다.
`DXM_GUI_DATA_HOME`은 개발 검증에서만 쓰는 별도 데이터 홈이며 배포 앱에 넣지 않습니다.

원작의 DeX·단일창 1~3, 기기별 화면·실행 옵션, 앱 목록·앱 설정, 무선 연결과
진단을 GUI로 조작하도록 연결했습니다. macOS에서는 트레이 대신 Dock을 사용하고
ADB/scrcpy는 번들 경로를 유지합니다. 전역 키 변환·F8 캡처·붙는 미니바를
Mac API로 추가했습니다. 키 변환은 현재 포커스를 가진 이 앱 소유 scrcpy 창에만
적용하며 손쉬운 사용 권한이 필요합니다. 오른쪽 Option이 한/영 키, F14가 Scroll Lock을
대신합니다. 오른쪽 Command는 왼쪽 Command 입력으로 전달하며 Windows의 F24와 다릅니다.
캡처에는 화면 기록 권한이 필요하며 Mac PNG 저장과 해당 휴대폰 전송을 구분합니다.
따라서 메인 설정 흐름은 대응하지만 모든 Windows 플랫폼 기능이 동일한 상태는 아닙니다.

Apple Silicon에서 별도 설정 폴더로 실제 GUI의 저장·슬롯 분리·메뉴 이동·입력
검증·언어와 테마 전환·로그 창·종료 후 재실행을 확인했습니다. 실행·저장 버튼은
스크롤과 관계없이 하단에 표시됩니다. 로그인 항목 등록은 시험하지 않았습니다.

USB SM-S942N / Android 17에서 화면 켜기·끄기, 한/영·오른쪽 Shift,
전체·영역·미니바 캡처와 휴대폰 사본, Esc·시간 초과 취소, 전체화면·접기·설정 창을
확인했습니다. 원래 크기 버튼은 현재 Mac 화면 밖으로 나가지 않도록 보정하며,
F14가 없는 키보드라 Enter 전환 실기는 미확인입니다. 보정 후 검증과 종료 결과는
`SESSION.md`에서 확인합니다. 이전 터미널 버전 실기나 자동 테스트를 이번 GUI의
실물 키보드 검증으로 간주하지 않습니다. 위 표의 미검증 항목은 배포 설명에서도 구분합니다.

원본 업데이트는 대응표의 기준 커밋과 새 원본을 비교합니다. 위 명령으로 받아온
원본을 검사하면 바로 비교할 공통 파일, Mac 보정이 필요한 파일, 화면 대조가 필요한
Windows 폼과 새 파일을 나눠 보여줍니다. 점검 스크립트는 파일을 자동 덮어쓰거나
기준 커밋·공개 릴리스를 바꾸지 않습니다. 별도 브랜치에서 반영한 뒤 두 아키텍처 빌드,
설정·정리 테스트와 Galaxy 실기를 확인하고 기준을 갱신합니다. 자동 병합이나 정기 감시를
설정한 것은 아닙니다.
