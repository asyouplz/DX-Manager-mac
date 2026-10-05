# TODO

## 2026-10-01 사용자 UI 오류 수정

- [x] 중앙 배치, 연결 해제 선택기/시작 보호, 폰 이름만 표시.
- [x] 일반 글자 +2 DIP, USB/Wi-Fi 정렬, 메뉴 위치, 버튼/펼침/고급 입력 배치.
- [x] 둥근 Region, 패널용 테마 스크롤 및 고급 접기 범위 초기화.
- [x] 페이지 전환 redraw 묶기, 문서별 스크롤/포터블 본문, 진단 테마/폰 카드.
- [x] Debug/Release 59/59 및 격리 UI 검사.
- [ ] 실제 폰의 연결 해제/설정, 체감 깜빡임, 문서 본문과 마우스휠/막대 조작, Win7/DPI 확인.

## 2026-10-01 Store 원본 기준 UI

- [x] 소스의 Pretendard 400/600, DIP 치수 및 색상·카드·컨트롤 재현.
- [x] 실제 라벨 겹침에 의한 시작 버튼 깨짐, 새로고침 아이콘, 숫자 중심 수정.
- [x] 설정 전체 49개 카드·펼침 항목, 범위별 저장과 입력 방식·대상 선택 연결.
- [x] 도움말 카드와 원본 기사·설명서, 오버레이와 첫 실행 확인 이식.
- [x] Debug/Release 59개 및 명령 없는 UI/저장 검증.
- [ ] Windows 7·다른 DPI·실제 폰의 새 UI 실기 확인.

## 2026-09-30 승인된 밝음·다크 UI

- [x] Windows 7/.NET 4.6.2 WinForms·GDI+로 승인된 메인·설정 시안 구현.
- [x] 상단 물리 기기 선택, 분리된 시작 앱 카드, 닫을 수 있는 오른쪽 아래 알림.
- [x] Companion 별도 메뉴, 기존 저장·권한·진단 동작 보존.
- [x] 기본 도움말 화면·로그 테마 및 작은 창 스크롤 배치.
- [x] Release 빌드·회귀 57개 및 명령 없는 UI 렌더링 확인.
- [ ] Windows 7·다른 DPI와 실제 두 휴대폰의 선택/모드 전환 UI 확인.
- [x] Store 기준 첫 실행 경고·확인 저장 기능을 별도 onboarding.json으로 이식.

## 2026-09-30 변경분 감사 및 앱 목록 수정

- [x] Store판을 참고해 물리 identity별 앱 목록 캐시·기기 전환 복원·늦은 응답의 원래 기기 저장.
- [x] 기기별 최근 앱 저장(schema 27), 저장된 시작 앱·프로필 선택 보존.
- [x] 앱 불러오기 완료 개수 오버레이, 5초 후 숨김과 연속 완료 메시지 교체.
- [x] 이번 변경·추가 코드 감사: stale 무선 스냅샷, 새 연결 정책 보존,
  진단 IPv6·이름 마스킹, 진단 카드·비동기 폼 수명, 글꼴 라이선스 보강.
- [x] Companion 종료 시 실행·대기 요청의 취소·이력·URI grant 정리를 소스에 보강.
- [x] 사용자 승인으로 Companion 2.1.3/versionCode 10 서명 APK에 반영하고 PC version/hash 검증값 갱신.
- [x] .NET 4.6.2 x64 Debug/Release·회귀 57개, Android 소스 테스트 13개·lintDebug·assembleDebug 검증.
- [ ] 수정 후 실제 A/B 휴대폰 목록 전환·완료 개수 메시지·늦은 A 응답의 B 화면 격리 확인.
- 메이님 실기 확인: Windows 11에서 일반 Release DeX, 파일 전송과 공유 저장소
  최상위 경로, 캡처 및 휴대폰별 미니바 독립 동작 정상. 취소·긴 이름·종료 경합까지
  확인된 것으로 확대하지 않는다.
- 감사 근거와 미완료 항목: `PORTABLE_BACKPORT_AUDIT_2026-09-30.md`.

## 2026-09-29 GitHub 포터블판 역이식

- 기준: 로컬 `v2.0.1` 태그 `2a4aff2`에서 분기한
  `feature/portable-backport-v2.0.1-20260928`. Store 제품 코드는 별도
  `store/winui3` 작업 폴더에 둔다.
- 순서: 포터블에서도 확인한 공통 버그 → 실행 설정·전송 상태 → Android 13+
  Companion → 다중 기기 진단 → 무선 mDNS·transport → WinForms UI 개편.
- [x] 공유 저장소 루트 `/sdcard`·`/storage/emulated/0` 전송 대상 보존.
- [x] 휴대폰→PC 폴더 내부의 Windows 금지문자 치환 충돌과 긴 이름의
  임시 파일 경로 보강.
- [x] 미니바 단축키와 전체 창 캡처의 live Scrcpy PID/HWND 소유권 확인.
- [x] 일반 명령과 관리형 전송 ADB의 종료 후 출력 대기를 유한 시간으로 제한.
- [x] DeX·단일창·wake-up Scrcpy와 직접 전송 ADB의 시작 시점에 종료 상태를
  다시 확인하고, 짧은 시작 잠금으로 Windows 종료 요청과 직렬화.
- [x] 단일창 시작 앱이 이미 선택된 상태로 설정을 불러올 때, 기기·모드 전환과
  앱 목록 갱신 뒤 저장 앱 프로필을 적용.
- [x] 사용자 지정 해상도 최근 5개 저장 및 목록 밖 활성 프로필 해상도 임시 표시.
- [x] PC→휴대폰 상태창의 transfer session PID/HWND를 사용하고 같은 PID에서
  늦게 생성된 HWND를 찾으며, 표시 중 창 위치를 따라간다.
- [x] .NET Framework 4.6.2 x64 Debug/Release 빌드와 다중 기기·전송 회귀
  52개 통과.
- [ ] Windows 7/11 실제 기기에서 루트 전송, 형제 이름 충돌, 긴 이름,
  최근 해상도 목록·프로필 복원, 미니바·전송 상태창 위치, Scrcpy 종료 직후 캡처를
  확인한다.
- [ ] 취소·종료 중 `Kill()` 뒤에도 직접 전송 ADB가 종료되지 않을 때의
  유한 대기와 프로세스 추적은 전용 재현·수명주기 검증을 더한 뒤 보강한다.
  Store 작업방 대조에서는 실기 재현이 없었고, 살아 있는 프로세스가 확인될 때까지
  단일 FIFO를 막고 임시 파일을 terminal/cleanup 처리하지 말라는 제약을 확인했다.
- [ ] 실제 Windows 7/11 종료·종료 취소 중 DeX·단일창·관리형 전송의
  새 프로세스 차단과 기존 세션 정리를 확인한다.
- [x] DX Companion 기준을 Android 13+ (`minSdk 33`), 2.1.2/versionCode 9로
  올리고 Store에서 사용한 서명 APK를 그대로 번들링한다.
- [x] 기존 Store APK의 일반 큐 완료 후 URI 해제와 DXMR v1 계약을 가져온다.
  다중 대기 요청 종료 보강은 위의 소스 수정·APK 미반영 항목을 따른다.
- [x] Android 15+ `dataSync` 서비스 제한 callback에서 진행 중 소켓을 닫고
  전송을 취소한 뒤 foreground service를 종료한다.
- [x] Store APK의 package·Android API·버전·서명·SHA-256을 검증하고, 복사본을
  `DXDisplayCleanup/bundled`에 보관하며 PC 런타임 검증값과 두 패키징 스크립트를 갱신한다.
- [x] Android 소스의 단위 테스트, Debug lint와 Debug APK assemble 검증.
- [ ] Android 13/15+ 실제 기기에서 파일·폴더 전송의 성공·실패·취소와 FGS
  timeout 정리를 확인한다.
- [x] 포터블 PC→휴대폰 완료·실패·취소를 선택 serial로 ADB broadcast하고,
  기존 Store APK의 `RECORD_TRANSFER_HISTORY`에 기록한다. 소켓 프로토콜은 유지한다.
- [x] 진단 화면을 선택 기기 하나에서 연결된 모든 기기로 확장하고, 기기별
  현재 runtime serial만 조회한다. 보고서에 모든 기기의 Android/One UI 정보를 포함하며
  기기 이름·identity·serial·IP·경로 마스킹 회귀 테스트를 추가한다.
- [x] 앱 목록 응답이 도착하기 전에 선택 기기가 바뀌면 이전 기기의 결과를 버리고,
  같은 물리 기기의 USB/Wi-Fi transport 전환은 허용한다.
- [ ] 두 휴대폰에서 A의 앱 목록을 늦게 받은 뒤 B로 전환해도 B의 목록·시작 앱·프로필이
  바뀌지 않는지 실기에서 확인한다.
- [x] Companion Android 소스를 Store 2.1.2의 로컬 전송 이력, 연결 경과시간,
  Light/Dark 화면·위젯과 Guardian cleanup 재시도 동작에 맞춘다. 배포 APK는 기존 검증 바이너리다.
- [x] Android 문서 제공자의 trim·slash 치환 후 형제 이름 충돌을 번호로 분리하고
  공식 서명 APK 2.1.4/versionCode 11 및 PC 버전·해시 검증값에 반영한다. 실기 확인은 다음 항목을 따른다.
- [ ] Android 13+ 실제 문서 제공자에서 trim·slash·대소문자 충돌 파일과 폴더 전송을 확인한다.
- [x] Android 11+ mDNS connect/pairing 파싱, wireless alias 분류, stable identity
  검증 뒤 동적 endpoint 갱신·재연결과 페어링 후 자동 발견/수동 폴백을 구현한다.
- [ ] Android 11+ 실제 단일·복수 기기에서 mDNS port 변경, 같은 모델, USB+Wi-Fi,
  alias 연결과 multicast 차단 시 수동 폴백을 확인한다.

## 다음 작업

- [x] v2.0.1 DeX 기기별 설정 표시 회귀 수정
  - [x] 첫 물리 identity 결속 뒤 기기별 DeX 설정 UI 재동기화
  - [x] 최초 다중 기기 선택에서 공통 기본값의 기기별 설정 덮어쓰기 차단
  - [x] Windows 버전 2.0.1과 기존 DX Companion 2.0.0(versionCode 6) 호환 확인
  - [x] .NET Framework 4.6.2 x64 Release와 39개 다중 기기 회귀 테스트

- [x] v2.0.0 공개 후보 준비
  - [x] Windows 버전 2.0.0과 DX Companion 2.0.0(versionCode 6) 일치
  - [x] 다중 기기 README·사용 설명서·FAQ·개발 문서 최신화
  - [x] 진단 페이지의 선택 기기 Android·SDK·One UI·보안 패치 진단
  - [x] 기기 이름·serial·IP·토큰·로컬 경로를 가린 진단 보고서 저장
  - [x] Windows x64/.NET Framework 4.6.2 Release와 전체 회귀 테스트
  - [x] Android 단위 테스트·lint·Release APK 서명 및 해시 재검증
  - [x] 공개용 ZIP의 필수 파일과 비밀키·설정·로그 제외 최종 검사

- [x] v2 기능 구현 후 구조 건강성 감사
  - [x] `MainForm` 기기 탭·연결 수명주기·연결 상태 보조 로직 분리
  - [x] 설정 루트와 설정 DTO·열거형 분리
  - [x] 사용자 입력 컨트롤을 기본 입력·값 입력·드롭다운 팝업으로 분리
  - [x] 구독되지 않은 v1 단일 기기 연결·분리 처리기 제거
- [ ] Scrcpy 주 창과 단일창의 프로세스 종료·출력 drain 공통화 검토
  - 종료 경합과 비정상 분리 회귀 테스트를 먼저 추가한 뒤 진행한다.
- [ ] `PhoneTransferReceiver`의 소켓 프로토콜과 PC 저장 경로·충돌 이름 처리를 분리
  - 대용량 전송·중단·재연결 테스트를 먼저 보강한 뒤 진행한다.
- [ ] `WirelessAdbService`의 기기별 연결 명령과 자동 재연결 snapshot 계산을 분리
  - USB·무선 동시 연결과 여러 무선 기기의 격리 테스트를 유지한다.
- [x] Android 11+ 무선 ADB의 현재 연결 endpoint를 mDNS로 자동 발견하는 코드
  - [x] parser/resolver 회귀 테스트와 C# 7.3/.NET 4.6.2 x64 Release 확인
  - [x] `_adb-tls-connect._tcp`와 pairing service를 분리하는 parser, IPv4/IPv6 endpoint 지원
  - [x] stable serial identity를 기준으로 후보를 고르고 모호하면 수동 경로 사용
  - [x] 연결 뒤 identity 재검증 후 dynamic host/port를 저장하고 wireless alias를 Wi-Fi로 분류
  - [x] 페어링 직후 endpoint 자동 검색, 검색 실패 시 수동 connect port 입력 제공
  - [ ] Windows 11 실제 Android 11+ 기기에서 아래 재연결·복수 기기·fallback 테스트
  - 번들 ADB의 `adb mdns services`에서 `_adb-tls-connect._tcp` 서비스를 조회하고,
    페어링용 `_adb-tls-pairing._tcp` 포트와 실제 연결 포트를 명확히 구분한다.
  - 검색 결과의 첫 항목을 임의로 선택하지 않는다. 물리 기기 identity, 기존 USB
    serial, 모델과 이미 검증된 transport를 대조해 현재 선택한 휴대폰의 endpoint만
    갱신하며, 같은 모델 여러 대와 복수 무선 기기를 안전하게 구분한다.
  - 휴대폰 재부팅, 무선 디버깅 재활성화, Wi-Fi 변경 등으로 연결 포트가 바뀌면
    자동 재연결 전에 새 endpoint를 다시 발견한다. 검증에 성공한 경우에만 기기별
    `WirelessHost`와 `WirelessPort`를 갱신한다.
  - mDNS를 사용할 수 없거나 방화벽·공유기가 multicast 검색을 차단하면 현재의
    수동 IP·연결 포트 입력과 저장된 endpoint를 폴백으로 유지한다.
  - 사용자가 선택한 USB 전용·무선 전용 연결 정책은 그대로 지킨다. 자동 발견을
    이유로 USB와 Wi-Fi 사이를 임의로 전환하지 않는다.
  - Windows 7의 legacy ADB와 `USB로 무선 준비`의 고정 5555 방식은 지원 여부와
    동작이 다르므로 Android 11+ 보안 무선 디버깅 경로와 분리한다.
  - 로그에는 발견 서비스, 대상 기기 판정 근거, 이전/새 endpoint, 폴백 사유와
    연결 결과를 남기되 6자리 페어링 코드와 인증 정보는 기록하지 않는다.
  - 한 대, 같은 모델 두 대, USB+Wi-Fi 혼합, 무선 두 대, 포트 변경, stale 서비스,
    mDNS 차단과 수동 폴백을 독립 회귀 테스트와 실제 기기에서 확인한다.
  - 구현과 실기 검증이 끝난 뒤 README, 영어·한국어 사용 설명서와 FAQ의 무선 ADB
    안내를 갱신한다. 기본 흐름은 `최초 1회 페어링 -> 연결 endpoint 자동 발견`으로
    설명하고, 수동 IP·포트 입력은 폴백으로 안내한다. 페어링 포트와 연결 포트가
    서로 다르며 연결 포트는 바뀔 수 있다는 설명, legacy 5555 방식, 관련 스크린샷과
    캡션도 함께 수정한다.
  - [ ] 실제 기기에서 한 대, 같은 모델 두 대, USB+Wi-Fi, 무선 두 대, 포트 변경,
    stale service, mDNS 차단과 수동 폴백을 확인한다.
- [ ] `AppSettings.EnsureDefaults`를 설정 범주별 정규화 helper로 축소
  - 기존 스키마 설정 파일 마이그레이션 표본을 만든 뒤 진행한다.
- [x] v2 1단계 물리 기기·ADB transport 기반
  - [x] v1.3.0 기준 `feature/v2-multi-device` 분기
  - [x] 물리 기기, transport, 방어적 복사 스냅샷 모델 추가
  - [x] 동일 identity의 USB·무선 병합과 서로 다른 휴대폰 분리
  - [x] transport별 상태, 기본 USB 우선과 명시적 transport 선택
  - [x] identity 조회 실패 시 기존 serial 매핑 또는 임시 identity 사용
  - [x] 상태 변화 세대 번호·이벤트와 방어적 복사
  - [x] .NET Framework 4.6.2 x64 Release 및 독립 회귀 테스트
- [x] v2 2단계 전역 ADB 대상 제거
  - [x] `AdbService.TargetSerial`과 프로세스 전역 `ANDROID_SERIAL` 의존 위치 목록화 및 제거
  - [x] 모든 기기별 ADB·Scrcpy 명령에 명시적 serial 전달
  - [x] 기기 선택 상태와 명령 실행 대상을 분리하고 시작·정리 시 serial을 캡처
  - [x] 한 기기의 명령·정리·취소 범위가 다른 기기와 섞이지 않는 독립 회귀 테스트
- [x] v2 3단계 기기별 런타임 세션
  - [x] DeviceMonitor, DeX, 단일창, Scrcpy, 화면 전원 상태를 물리 기기별로 분리
  - [x] Companion reverse·수신 토큰과 PC↔폰 전송 큐를 기기별로 분리
  - [x] 물리 기기와 독립 서비스 묶음을 1:1로 결속하고 USB·무선 전환 시 유지
  - [x] 연결 해제 상태를 정리 증거와 함께 보존하고 의미 없는 감시 갱신은 무시
  - [x] .NET Framework 4.6.2 x64 Release 및 기기 격리 회귀 테스트
- [x] v2 4단계 다중 기기 선택 UI와 실기 검증
  - [x] 메인 화면 기기 선택 UI와 연결 방식·상태 표시
  - [x] 탭별 독립 DeX·단일창·양방향 전송 서비스 선택과 비선택 세션 유지
  - [x] USB·무선 transport 변경, 연결 해제, 전체 종료의 기기별 정리 경로
  - [x] .NET Framework 4.6.2 x64 Release 및 26개 다중 기기 회귀 테스트
  - [x] 두 휴대폰 동시 DeX·단일창 실행과 탭별 실행 상태 복원
  - [x] 두 휴대폰 PC→폰 파일 전송과 각각의 연결 해제 격리
  - [x] 두 휴대폰 폰→PC 파일 전송과 연결 상태 전체 정상 종료 정리
- [x] v2 5단계 기기별 무선 ADB 설정
  - [x] 설정의 연결 페이지에서 대상 휴대폰을 명시적으로 선택
  - [x] 선택한 휴대폰의 정확한 USB serial로 무선 준비와 IP 감지 수행
  - [x] 물리 identity별 USB·무선 모드, IP, 포트와 자동 재연결 저장
  - [x] 혼합 USB·무선 연결과 복수 무선 자동 재연결 지원
  - [x] 기존 전역 무선 설정을 최초 기기 프로필로 안전하게 이관
  - [x] .NET Framework 4.6.2 x64 Release 및 31개 다중 기기 회귀 테스트
- [x] v2 다중 기기 식별·표시 마무리
  - [x] 저장된 USB·무선 연결 정책과 실제 감지 transport 상태를 분리해 표시
  - [x] USB·무선 정책 사이 자동 fallback 제거와 선택 transport 대기 처리
  - [x] 연결 방식 변경·분리 시 이전 세션·전송·ADB reverse 정리
  - [x] 메인 기기 탭 전환 시 설정 창을 유지하고 선택 기기 정보 새로 고침
  - [x] 휴대폰→PC 수신 파일을 휴대폰 표시 이름별 하위 폴더로 분리
  - [x] DeX·단일창 scrcpy 제목에 휴대폰 표시 이름 추가
  - [x] 연결 시 DeX 자동 시작을 연결된 각 휴대폰의 독립 런타임으로 확장
  - [x] 한 대 사용 시 기기 탭 숨김과 두 번째 기기 확인 후 실행 중 탭 유지
  - [x] 기기 선택 UI를 왼쪽 사이드바로 이동하고 시작 시 최신 모델 우선·순차 연결 시 최초 연결 순서 유지
  - [x] .NET Framework 4.6.2 x64 Release 빌드 및 35개 다중 기기 회귀 테스트
- [ ] Windows 종료 중 ADB 오류 반복 방지
  - [x] 새 ADB·보조 프로세스 실행 차단과 실행 중 프로세스 종료 gate
  - [x] DX Manager가 선택한 절대 경로의 ADB 프로세스만 종료
  - [x] 정상 종료의 기기 설정 복원·overlay 정리·`adb kill-server` 경로 유지
  - [x] 프로세스 차단·취소 회귀 테스트 추가
  - [x] Windows 7 회사 PC 1차 확인: 오류창 약 10회에서 2~3회로 감소
  - [x] 제한 시간 내 overlay·절전모드 해제 복원 후 ADB 최종 차단 경로 추가
  - [x] 자식 프로세스 네이티브 오류 대화상자 억제 모드 추가
  - [x] 일반 종료 후 분리된 ADB 서버와 번들 보조 프로세스의 절대 경로 최종 정리
  - [x] 이름이 같은 다른 경로 프로세스를 보존하는 회귀 테스트 추가
  - [x] 공개 UI에 넣었던 Windows 종료 모의 테스트를 RC 검증 후 제거
  - [x] 실제 종료 시 새 ADB 실행·종료를 없애고 미리 연결된 Companion 소켓만 사용
  - [x] Companion 미설치·미검증 기기는 실제 Windows 종료 정리를 건너뛰도록 분리
  - [x] Companion 연결 손실 시 기본 5분 유예와 재연결 취소, 즉시 정리 및 자동 정리 안 함 옵션 추가
  - [x] .NET Framework 4.6.2 Debug 빌드와 37개 다중 기기 회귀 테스트 통과
  - [x] Windows 11 RC2 다중 기기 overlay·절전모드 해제 정리 확인
  - [x] Windows 11 실제 종료에서 ADB 오류창 제거와 Companion 기기 설정 복원 확인
  - [ ] Windows 7 회사 PC에서 오류창 제거와 기기 설정 복원 재확인

- [x] v1.2.0 구조 분리
  - [x] MainForm·SettingsForm feature partial 분리
  - [x] 파일 전송 IPC·처리·ADB·원격 작업·진행 상태 분리
  - [x] 폴더 전송 계획과 실행 결과 모델 분리
  - [x] .NET Framework 4.6.2 x64 Debug/Release 빌드
- [x] v1.2.0 실기 회귀 테스트
  - DeX·단일창 시작/중지와 USB·무선 재연결
  - 화면 끄기·잠자기 방지·키보드 보정과 비정상 분리 정리
  - 단일 파일·폴더·Unicode 파일 전송, 취소와 연결 해제
  - Windows 11 확인 후 Windows 7 SP1 확인

- [x] DX Companion 실제 Galaxy 기기 검증
  - [x] 공식 Release APK 설치와 package/certificate 재확인
  - [x] ADB 1회 권한 부여 전·후 상태 표시
  - [x] 앱 본체의 활성 overlay 삭제와 삭제 후 재조회
  - [x] 빠른 설정 타일·2 × 1 홈 위젯과 절전모드 해제 복구 확인
- [x] DX Manager의 정리 앱 package/v2 인증서 검증과 실제 권한 부여 연결
  - 부여 직전·직후 재검증 및 사후 검증 실패 시 권한 회수
- [x] v1.3.0 번들 DX Companion 관리 코드와 Release 빌드
  - [x] 번들 APK SHA-256/v2 인증서 사전 검증
  - [x] 현재 선택 기기 명시적 설치·업데이트·재설치·삭제
  - [x] 설치 후 package·versionCode·서명·권한 재검증
  - [x] 삭제 전 해당 기기의 파일 수신과 ADB reverse 정리
  - [ ] 실제 기기에서 진단 UI 설치·업데이트·재설치·삭제 회귀 확인
- [x] v1.3.0 포터블 ZIP에 APK 포함 및 비밀키·설정·로그 제외 검사
  - 실제 설치·삭제 회귀 뒤 공개 직전에 같은 검사를 한 번 더 수행
- [x] v1.3.0 공개 후보 x64/.NET 4.6.2 Release와 ZIP 최종 재검증
  - Windows 빌드 경고 0·오류 0, Android 단위 테스트·Release lint 통과
  - 필수 파일, APK 해시·v2 서명과 비밀키·설정·로그 제외 확인
- [x] Companion PC 수신 준비 상태 실기 회귀
  - DX Manager 실행·종료와 USB/무선 연결·분리 시 준비/대기 표시 전환
  - 비정상 종료 뒤 저장된 세션 정보가 남아도 실제 수신기 확인 실패 시 대기 표시
  - 공유 메뉴 전송 직전 수신기 재확인
- [x] 캡처·드롭 파일 휴대폰 저장 경로 ADB 폴더 찾아보기

- [x] v1 최초 휴대폰 고정 로직 실기 확인
  - 시작 시 USB 휴대폰 2대 중 한 대 선택 및 고정
  - 실행 중 다른 휴대폰 연결 무시
  - 고정 휴대폰 분리 시 다른 휴대폰으로 자동 전환하지 않음
  - 같은 휴대폰 재연결 및 USB↔무선 전환 허용
- [x] Windows 7에서 최신 입력/설정 UI 회귀 확인
- [ ] Scrcpy 4.0/SDL3 오른쪽 Shift 재현 내용을 upstream에 보고
- [ ] Scrcpy 4.1/SDL3에서도 오른쪽 Shift 호환 보정의 필요 여부 실기 확인
- [ ] Upstream 수정 시 오른쪽 Shift 치환 우회 제거 여부 검토
- [ ] 한국어 노트북의 `VK_HANGUL + extended scan 0x38` 한영키 실기 확인
  - 브라질 ABNT/ABNT2 또는 AltGr 키보드에서 `?`, `@` 등 특수문자 회귀 확인
- [x] 기기 인식 후 실제 Scrcpy 시작 전 대기 옵션(0~60초, 기본 1초)

## 배포 준비

- [x] `dist\DX Manager` 폴더와 버전별 x64 ZIP 패키징 스크립트
- [x] 생성된 공개 패키지 최종 배포 체크리스트
- [x] 패키징 전 Debug/Release의 logs/screenshot 테스트 파일 자동 제거
- [x] 준비된 한국어/영어 스크린샷을 README와 사용 설명서에 배치
- [x] 번들 구성요소 버전 확인과 제3자 라이선스 원문/고지 포함
- [x] 한국어 Q&A 초안 사용자 검토 및 수정
- [x] 한국어 Q&A 승인 후 독립 영문 FAQ로 번역
- [x] Windows 7 SP1~11 v1.1.0/1.2.0 최종 회귀 테스트
  - [x] Windows 11 실제 기기 관리형 Unicode 단일 파일 전송과 proxy 전달
  - [x] x64 Release 빌드 및 v1.1.0 ZIP 구성 검증
  - [x] Windows 7 SP1~11 Scrcpy 4.1 DeX/단일창 실행과 종료 UI 회귀
  - [x] Windows 7/11 한글·Unicode 복수 파일과 폴더 전체 전송 확인
  - [x] 사용자 대상 경로, 파일·폴더 충돌 이름, 취소와 독립 상태창 확인
  - [x] 관리형 전송 끄기 후 새 창에서 Scrcpy 순정 동작 복귀
  - [x] 설정·진단의 실제 ADB `Version ...` 값 표시 확인
- [x] GitHub 첫 공개 Release 게시 및 저장소 public 전환
- [x] v1.3.0 공개 Release 게시와 DX Companion 번들 배포
- [x] DX Manager 자체 소스 라이선스를 MIT로 확정

별도 설치 프로그램은 보류한다. v1.3.0 WinGet manifest는 등록됐다.
- [ ] 별도 `winget-pkgs` 작업 사본에서 v2.0.0 manifest의 제출·승인 상태를
  확인하고, 필요하면 공개 자산 URL과 SHA-256으로 갱신한다.

## 독립 FAQ 반영 항목

1. 비정상 종료 뒤 휴대폰에 작은 보조 화면이 남았을 때 제거 방법
2. 삼성 브라우저 자동 실행 전에 앱을 강제 종료하는 이유
3. 휴대폰을 두 대 이상 연결했을 때 v2의 독립 세션과 연결 정책
4. 1600×900보다 낮은 해상도에서 DeX UI 일부가 잘리는 이유
5. 해상도/DPI에 따라 바탕화면 배치와 배경화면이 달라지는 이유
6. 최근 앱 화면의 데스크톱이 이상할 때 새 데스크톱으로 복구하는 방법
7. DPI를 120보다 낮게 설정할 수 없는 이유
8. Scrcpy 서버 push 속도가 낮게 표시될 때 USB 케이블 확인
9. 무선 ADB 연결/재연결 실패 시 네트워크와 포트 점검
10. `unauthorized`, `offline` 장치와 RSA 승인 문제
11. Scrcpy 4.0에서 오른쪽 Shift를 왼쪽 Shift로 보정하는 이유
12. 기기 연결 후 시작 대기와 프로세스 제한시간의 차이
13. 사용 중 USB가 분리됐을 때 정리와 같은 휴대폰 재연결 동작
14. 휴대폰 화면 끄기와 stay-awake 옵션의 동작
15. 비정상 종료 뒤 충전 중 화면이 계속 켜질 때 절전모드 해제 복구
16. Windows 7 요구사항과 실행 파일만 복사하면 안 되는 이유
17. 관리형 드래그 앤 드롭 파일 전송, Unicode 이름, 충돌과 순정 전환
18. One UI 7.x 이하에서 검은 DeX 창이 나타날 수 있는 이유
19. ADB 공통 `1.0.41` 문구와 실제 `Version ...` 빌드 값의 차이
20. 금융·게임·DRM 앱의 실행 거부 또는 검은 화면
21. DeX에서 실행한 앱이 휴대폰 화면에서 열리는 경우
22. HID 마우스 사용 중 포인터가 scrcpy 창에 잡히는 동작
23. DX Companion 설치·서명 검증과 권한 버튼 비활성화
24. DX Companion 휴대폰→PC 파일·폴더 전송 준비와 사용 방법

## 2026-10-01 후속 확인

- [x] 일반 글자 확대 +1 DIP로 축소, 사용 라벨/카드 폭/하단 여백 수정.
- [x] 기기 정보 새로고침 오른쪽 이동 및 요약 여백 축소.
- [x] 로그 버튼-설명 겹침 제거, 네이티브 로그 스크롤 테마, 배경 캐시/패널 버퍼.
- [x] 고급 옵션 표시 전용 예시 및 문서별 스크롤 위치 보존.
- [ ] 실제 설정/고급 옵션 스크롤의 체감 부드러움과 흰 줄, 로그 스크롤 테마 재확인.

## 2026-10-02 설정 배치 회귀

- [x] 임시 좁은 배치에서 입력 폭을 영구 변경하던 오류 수정·복원 검사.
- [x] 휠/막대/로그 공통 얇은 스크롤, 다크 배경, 네이티브 범위 사용.
- [x] 최하단 카드 도달, 로그 정렬, 도움말 중앙 정렬, 즉시 예시 표시 수정.
- [x] 실제 데스크톱 검증 사본의 기본 설정 배치/다크 스크롤 캡처 확인.
- [ ] 실제 폰 연결 상태 갱신 및 직접 휠 조작·Win7/DPI 최종 확인.

## 2026-10-02 후속 UI/시작 경로

- [x] 단일창 앱 미선택 초기 차단 및 회색 안내 버튼, DeX 앱 선택 사항 유지.
- [x] 공통 모서리/스크롤 배경/반투명 오류 팔레트 수정.
- [x] 경로 시작선, 동적 진단/환경 결과, Companion 중복 행, 정보 링크 수정.
- [x] Release 연동 프리뷰·행동 검증, Debug/Release 회귀 59개.
- [ ] 실제 연결 폰의 클릭·비동기 갱신 및 Win7/DPI 검증.

## 2026-10-02 해상도/오른쪽 정렬

- [x] 사용자 해상도 순서·구분선, 숫자 즉시 표시와 모드 왕복 유지.
- [x] 드롭다운 닫은 뒤 모달 열기, 가로 입력 초기/클릭 선택.
- [x] 스크롤 유무와 무관한 카드 폭, 닫기 버튼 오른쪽 정렬.
- [ ] 실제 데스크톱 포커스·Win7/DPI 최종 확인.

- [x] 사용자 지정 해상도 구분 제목과 맨 아래 사용자 지정... 메뉴 분리, 제목 선택 차단.

## 2026-10-03 요청 반영

- [x] 테마 갱신 시 알림 사각 배경 재발, 실제 카드 배경으로 모서리 복원.
- [x] 앱 미선택 안내만 앱 선택 시 자동 닫기, 다른 오류 유지.
- [x] DeX 준비/단일창 준비·대기 문구, 설명 제거 및 제목 중앙 정렬.
- [x] 매 실행 동의창 반복(사용자가 종료 요청할 때까지 유지), 동의 기록 보존.
- [x] 사용자 확인 S26 Ultra·SDK37·OneUI9.0 안내만 정상 동작 확인으로 분류.
- [x] Debug/Release 60개 및 알림·준비 문구·레이아웃 검증.
- [ ] 실제 화면/폰 비동기 갱신 및 Win7/DPI 확인.


## 2026-10-05 connection / Companion follow-up

- [x] USB/Wi-Fi/both observed connection badge, vector icons and label width; light/dark fixture verification.
- [x] New DeX/single-window USB-first launch without migrating existing Wi-Fi sessions.
- [x] USB disconnect stops captured USB sessions; no automatic Wi-Fi restart, even with AutoStart enabled.
- [x] Reconnected USB is available for another manual launch while a Wi-Fi session remains running.
- [x] Companion2.1.4 signed APK, PC exact version/hash checks and packaging scripts.
- [x] Store later-update note written; Store package/submission remains unchanged.
- [ ] Actual phones: both-connected launch log uses USB; unplug USB stops its DeX/single sessions; no automatic Wi-Fi start; manual start uses remaining Wi-Fi.
- [ ] Actual document providers: colliding file/folder names and nested contents remain distinct on transfer.

## 2026-10-05 reconnect regression correction

- [x] Restrict USB-loss auto-start suppression to the current fallback connection episode; clear when original transport returns or the physical device connects anew.
- [x] Preserve automatic-start OFF and USB-first automatic launches while another Wi-Fi session remains running.
- [x] Widen Wi-Fi icon and label spacing; verify light/dark badges and62 regressions plus reconnect fixture.
- [ ] Physical USB-only: auto-start at program startup, unplug during DeX, reconnect USB -> automatic DeX again when setting ON.
- [ ] Physical USB+Wi-Fi: unplug USB -> no immediate Wi-Fi auto-start; reconnect USB -> automatic USB DeX when setting ON; confirm OFF does not auto-start.
## 2026-10-05 Fluent icon trial

- [x] Preserve manual renderer/source snapshots and original large phone illustration; apply31 licensed Microsoft Regular assets to small icons.
- [x] Extract official mouse component from Keyboard Mouse20Regular and document provenance.
- [x] Mini-bar observed USB/Wi-Fi/both status, live per-device snapshot updates, new-bar initial state and themed Fluent command icons.
- [x] Release build,62 regressions, transparency/tint, light/dark control renders and mini-bar isolation/collapse/status fixtures.
- [x] User accepted the Fluent appearance and reported successful physical validation before final2.5.0.
- [ ] Store icon/APK changes: acceptance and implementation handoff are documented; Store product changes remain separate.
## 2026-10-05 v2.5.0 final acceptance

- [x] User-reported physical validation and final2.5.0 decision recorded; older per-scenario lists are historical validation boundaries, not automatically all independently retested.
- [x] Consent once until acknowledgement; accepted profiles do not repeat and settings reset preserves the state.
- [x] Release62 tests, pinned Companion2.1.4, final package/ZIP/required files/privacy exclusion and SHA256 verification.
- [x] Final release notes, checksums and packaging paths prepared for user virus inspection.
- [ ] GitHub push/tag/release only after virus checking and the user's explicit upload instruction.
- [ ] Rare ADB Kill-survival scenario remains an unreproduced follow-up candidate; no optional fix added to the frozen final.
