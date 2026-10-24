# DX Manager v2.5.0

## English

Added 2026-10-19: experimental maximum120 FPS (default60), one mandatory
warning per actual120 start, prior screen-off preference restoration, same-phone
120-screen-on priority, and local per-version EN/KO change notes for existing users.
A new EXE/ZIP has been prepared; the October16 antivirus result applies only to
the previous exact files. The official Companion2.1.6 and scrcpy5.0.1 are unchanged.

Final portable release prepared 2026-10-16. Windows 7 SP1,8.1,10 and 11 x64;
.NET Framework 4.6.2 or later. The maintainer reports completed clean antivirus checks; publication still awaits an explicit instruction.

- Bundle scrcpy 5.0.1 and select hardware decoding automatically for DeX and all three single windows.
- Refresh the light/dark UI, Fluent icons, transfer windows, help layout and text rendering.
- Keep USB-first new launches and independent per-phone DeX/single-window/transfer state.
- Restore the main window when its EXE is opened again; close auxiliary windows when hiding to tray.
- Keep missing-app notices scoped to their device and single-window slot; improve wireless/TLS state handling.
- Check stable GitHub updates once per local day, with a background deadline and no offline retry loop.
  Manual checking is beside third-party notices; automatic notices use a nonmodal lower-right banner.
- Show the selected scrcpy executable's full version in environment inspection.
- Include the officially signed shared Companion 2.1.6/code13, Android13+. It retains duplicate-share
  protection and stops session protection once the PC disconnects and recovery settings are verified inactive.
  Connected sessions and settings that still need recovery retain protection.
- Require checked first-run consent until accepted; retain acknowledgement on later launches.
- Ship runtime files, required licenses and a short README. Usage and FAQ are embedded in the app;
  source guides/screenshots, personal settings, saved consent, logs, debug symbols and test tools are excluded.
- Automatic AI app detection/keymaps and the private Companion are intentionally excluded.

The existing Companion must be updated through Settings > Companion for the new behavior.
The package does not install APKs automatically. See FINAL_250_2026-10-16.md for final hashes,
verification evidence and remaining physical-test boundaries.

## 한국어

2026-10-19 추가: 최대120 FPS 실험적 옵션(기본60), 실제120 실행마다 경고,
이전 화면 끄기 값 복원과 같은 폰의120 화면 켜짐 우선, 기존 사용자의 로컬
버전별 한·영 변경사항 안내를 넣었습니다. 새 EXE/ZIP은 다시 검사해야 하며
10월16일 검사 결과는 이전 파일에 대한 기록입니다. 공용 APK와 scrcpy는 동일합니다.

2026-10-16 준비한 정식2.5.0 포터블입니다. Windows 7 SP1·8.1·10·11 x64,
.NET Framework 4.6.2 이상을 지원하며, 사용자가 바이러스 검사 완료를 보고했으며 메이님의 명시적 배포 지시를 기다립니다.

- scrcpy 5.0.1을 포함하고 DeX·단일창 세 슬롯에서 하드웨어 디코딩을 자동 선택합니다.
- 밝음·다크 UI, Fluent 아이콘, 전송창, 도움말 배치와 글자 렌더링을 정리했습니다.
- 새 실행의 USB 우선 선택과 휴대폰별 독립 세션을 유지합니다.
- EXE 재실행 시 메인창 복원, 트레이 숨김 시 부속 창 종료, 슬롯별 앱 미선택 알림을 반영했습니다.
- 무선/TLS 연결 상태 처리를 개선하고 환경 검사에서 scrcpy 전체 버전을 표시합니다.
- 업데이트는 하루 한 번 백그라운드에서 확인하며 오프라인 재시도 반복은 하지 않습니다.
  수동 버튼은 제3자 라이선스 옆, 자동 안내는 메인 오른쪽 아래 배너입니다.
- 공식 서명 공용 Companion 2.1.6/code13(Android13+)을 포함합니다. 중복 공유 방지를 유지하며,
  PC 연결이 끊기고 가상 화면·잠자기 방지가 모두 정리됐음을 확인하면 감시와 알림을 종료합니다.
  정상 연결 중이거나 복구할 항목이 남아 있으면 보호 기능을 유지합니다.
- 첫 실행 동의는 확인란을 선택해야 진행할 수 있으며 동의 후 재실행에서는 반복하지 않습니다.
- 실행 파일·필수 라이선스·짧은 README만 배포합니다. 도움말과 FAQ는 앱에 내장돼 있으며,
  저장소 문서·스크린샷·개인 설정·동의 기록·로그·디버그 파일·테스트 도구는 포함하지 않습니다.
- 개인 테스트판의 AI 앱 자동 감지·키맵과 테스트 APK는 포함하지 않습니다.

새 동작을 사용하려면 설정 > Companion에서 동봉된 정식 APK로 업데이트하세요.
APK는 자동 설치하지 않습니다. 최종 해시·검증 범위는 FINAL_250_2026-10-16.md에 기록합니다.

## SHA-256 and verification / 해시·검증

The exact EXE, proxy, APK and ZIP hashes and the scope of the supplied antivirus evidence are in
[VERIFICATION_v2.5.0.md](VERIFICATION_v2.5.0.md). The October19 rebuild has new EXE/ZIP hashes and requires a fresh maintainer scan.
10월19일 재빌드 파일은 다시 검사해야 합니다. 이전 검사본은 개발 기록으로 보관했고 배포는 아직 하지 않았습니다.
