# DX Manager v2.5.0

## English

Final local portable build prepared at the user's request. GitHub publication waits for the user's virus check and explicit upload instruction.

### Changes

- Renewed light/dark Windows7-compatible interface with Fluent Regular icons, settings cards, local help and diagnostics. Product logo and custom phone artwork retained.
- First-run consent respects the saved acknowledgement; the temporary every-launch review override is disabled.
- Same-phone USB/Wi-Fi/both connection display, including mini-bars. New manual/automatic launches prefer authorized USB; running sessions retain captured serials.
- USB loss stops its sessions without immediately starting over Wi-Fi. Reconnection follows the existing DeX auto-start preference.
- Single windows require a selected app before any launch-related ADB/wake-up; DeX can start without a selected app.
- Device-scoped app catalogues/recent profiles, custom resolutions, transfer/capture/process safety, diagnosis and UI alignment/scroll/notice fixes.
- Bundled officially signed DX Companion2.1.4/code11, Android13+. Includes queued-request shutdown cleanup and per-parent normalized-name collision disambiguation; original content URIs and DXMR v1 are preserved.

### Package and verification

Windows7 SP1,8.1,10,11 x64; .NET Framework4.6.2 or later; bundled scrcpy4.1. Keep the complete portable folder together. Companion is optional and is not installed automatically.
The user reported successful real-device validation. Local Release62 regressions, Android20 tests/lint/signed-build checks, and UI/connection/mini-bar fixtures passed during this work. These results do not constitute a virus scan or independent coverage of every OS, provider or rare termination failure.

### Remaining follow-up

A rare direct-transfer ADB process surviving Kill remains an unreproduced follow-up candidate. Store Edition changes are documented separately and are not bundled into this portable release. Virus scan and GitHub publication remain pending user action.

## 한국어

메이님 실기 확인 후 요청한 포터블 최종 준비 버전입니다. 바이러스 검사 후 메이님이 업로드를 지시할 때 GitHub에 게시합니다.

### 변경 사항

- 밝음·다크 UI, Fluent Regular 아이콘, 설정·로컬 도움말·진단 개선. 제품 로고와 큰 휴대폰 그림 유지.
- 동의창을 첫 실행 동의가 저장될 때까지만 표시하며, 이후 실행에서는 반복하지 않음.
- 메인·미니바의 USB/Wi-Fi/동시 연결 표시. 새 실행은 USB 우선, 기존 세션은 캡처한 연결 유지.
- USB 해제 직후 남은 Wi-Fi로 자동 재실행하지 않으며, 실제 재연결은 DeX 자동 실행 설정을 따름.
- 단일창 앱 미선택 시 실행용 ADB/wake-up 전에 차단. DeX는 시작 앱 미선택으로도 실행 가능.
- 기기별 앱 목록·최근 앱/프로필, 사용자 해상도, 전송·캡처·프로세스 정리 및 UI 배치·스크롤·오류 안내 보강.
- 공식 서명 DX Companion2.1.4/code11(Android13+) 포함. 대기 전송 종료 정리와 이름 정리 후 형제 항목 충돌을 분리함.

### 검증·업데이트

Windows7 SP1~11 x64/.NET4.6.2 이상, scrcpy4.1을 사용합니다. 전체 포터블 폴더를 함께 유지하세요. Companion은 자동 설치하지 않습니다. 기존 config를 백업·이전하면 기기 설정과 동의 기록을 유지합니다.
사용자는 실기 검증 후 정상 작동을 보고했습니다. Release 회귀62개, Android20개 및 lint/공식 서명 검사, UI·연결·미니바 컨트롤 검증 기록이 있습니다. 바이러스 검사 결과는 아직 기록하지 않았습니다.
드문 ADB 강제 종료 실패의 재현/보강은 후속 후보로 남깁니다. Store 제품과 개발선은 분리하며 GitHub 업로드는 별도 지시 후 진행합니다.

## Local artifact SHA256

- DX-Manager-v2.5.0-win-x64.zip: `B2064404BB45B65FA863558C82898C5B1BFFAC46CB7035BA5E55CEA2892765E0`
- DXManager.exe: `BACEA6027137EC0ACE770133034F258EF36F68CA977FD03FF9395F58717D3632`
- Bundled DX-Companion.apk: `95DAF4E734FD36FE07AD8388FE8E4C98D96D1EFA0A8E359D8C8E3E27383B6536`