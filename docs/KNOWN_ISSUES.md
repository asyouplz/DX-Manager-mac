# Known Issues and Constraints

## 네트워크 격리

무선 ADB는 PC와 휴대폰의 직접 로컬 통신이 필요하다. 같은 대역이어도 게스트
Wi-Fi, AP/client isolation, VLAN 또는 인트라넷 차단이 있으면
`adb connect`가 10060 timeout으로 실패한다.

ASUS 공유기는 게스트 네트워크의 인트라넷 접근 허용과 AP 격리 해제를
확인한다. 개발 중 5GHz 초기 연결 실패가 2.4GHz 연결 및 ADB 재시작 뒤
해소됐다. 재현 시 ARP, 5555 포트와 공유기 격리를 먼저 확인한다.

## 무선 준비 지속성

휴대폰 재부팅이나 Android 정책으로 `adb tcpip`가 풀리면 USB로 무선 준비를
다시 실행한다. IP는 비워두면 자동 감지된다.

## Windows 7

자동화된 Windows 7 테스트 환경은 없다. 릴리스 전 회사 PC 실기 확인이
필요하다.

## 여러 휴대폰

v2는 연결된 여러 물리 휴대폰을 동시에 관리한다. 각 휴대폰은 독립된 DeX·
단일창·설정·파일 전송·Companion 세션을 가지며, 같은 휴대폰의 USB와 무선
ADB transport는 하나의 기기로 병합한다. USB 또는 무선 중 사용자가 선택한
연결 방식만 사용하며 반대 방식으로 자동 전환하지 않는다.

현재 자동화 및 실기 기준은 휴대폰 두 대다. 설계상 더 많은 기기도 등록할 수
있지만, PC 자원·ADB 안정성·Samsung 펌웨어에 따른 실사용 상한까지 보장하지는
않는다.

## Android와 One UI 호환

현재 정상 동작을 확인한 휴대폰 기준은 Android 16 / One UI 8.x가 설치된 DeX
지원 Galaxy 기기다. One UI 7.x 이하에서는 가상 디스플레이에 DeX가 원활하게
나타나는지 확인되지 않았으며 검은 Scrcpy/DeX 창이 열릴 수 있다. 기기 모델,
Samsung 펌웨어와 클래식 DeX 구현 여부에 따라서도 결과가 달라질 수 있다.

단일창은 Scrcpy 자체 가상 디스플레이를 사용해 동작할 수 있지만 HID 키보드와
마우스 호환성까지 보장하지 않는다. 특정 기기에서 불안정하면 두 HID 옵션을
끄고 비교할 수 있으나 이를 해당 버전의 공식 지원으로 간주하지 않는다.

## Samsung DeX 저해상도와 DPI

Samsung DeX의 기본 최소 해상도는 1600×900이다. 더 낮은 가상 해상도도
실행될 수 있지만 앱 서랍 상단이 잘리는 등 일부 DeX UI가 정상 배치되지
않을 수 있다. 해상도와 DPI 조합에 따라 DeX가 서로 다른 바탕화면 배치와
배경화면 상태를 사용하는 것도 Samsung DeX 동작이다.

DPI는 120 미만에서 overlay 생성이 실패하므로 DX Manager가 입력을 거부하고
편집 전 값으로 복원한다. 매우 높은 DPI는 생성되더라도 UI가 지나치게 커져
사용하기 어려울 수 있다. 사용자 지정 가로·세로 값은 Android overlay 제한에
맞춰 각각 4096을 넘길 수 없다.

## 비정상 종료 뒤 overlay 잔존

정상 종료에서는 overlay를 제거한다. Windows 세션 종료 중에는 새 ADB 프로세스를
시작하지 않으며, 이미 인증되어 연결된 DX Companion guardian 세션이 있을 때만
overlay 제거와 `절전모드 해제` 복원을 요청한다. 다만 프로세스 강제 종료,
전원 차단, 이미 끊어진 기기, Companion 미설치·미연결 또는 Windows가 정리 시간을
주지 않는 경우에는 Android의 보조 디스플레이나 `절전모드 해제` 상태가 휴대폰에
남을 수 있다. 특히 Windows 7의 실제 종료 순서는 시스템과 ADB 상태에 따라 달라질
수 있으므로 Windows 종료 자체를 정상적인 세션 정리 방법으로 보장하지 않는다.
DX Companion을 사용하거나 개발자 옵션의
`보조 디스플레이 시뮬레이션`에서 임의 항목을 켰다가 다시 끄면 제거할 수 있다.
자세한 복구 절차는 사용자용
[`FAQ_KO.md`](FAQ_KO.md)에 정리했다.

## 외부 Scrcpy

Scrcpy 3.3.4와 4.x의 주요 옵션 차이는 자동 처리한다. 3.3.4에서는
`--keep-active` 대신 `-w`를 사용하고 `--flex-display`를 제외한다.
그 밖의 과거/향후 버전과 사용자가 직접 입력한 추가 인자의 호환성까지
보장하지는 않는다. 기준 번들은 Scrcpy 4.1이다.

## Scrcpy 4.x/SDL3 오른쪽 Shift 호환 보정

Windows용 Scrcpy 4.0/SDL3에서 물리 오른쪽 Shift가 Android로 정상 전달되지
않는 현상을 재현했다. 3.3.4/SDL2에서는 정상이며 `-K`, `-M` 사용 여부와
관계없이 발생했다. 이 4.0 재현 근거를 바탕으로 현재 SDL3 기반 Scrcpy 4.x
클라이언트에도 호환 보정을 적용한다.

DX Manager는 SDL3 Scrcpy가 활성화된 동안 오른쪽 Shift를 왼쪽 Shift로
치환한다. 타이핑은 정상화되지만 Android 앱에서 좌우 Shift를 서로 다른
키로 사용하는 경우에는 두 키를 구분할 수 없다. 다른 Windows 앱과 SDL2
Scrcpy에는 영향을 주지 않는다. Upstream 보고 및 수정 여부를 추적한다.

## 관리형 파일 전송

DX Manager 관리형 전송 대상은 `/sdcard/` 또는 `/storage/emulated/0/` 아래의
하위 폴더로 제한한다. 단독 APK 설치와 그 밖의 ADB 명령은 Scrcpy의 순정
동작을 유지한다. Android 경로의 각 구성요소는 UTF-8 기준 255바이트를 넘을
수 없으며, 충돌 접미사를 붙인 최종 이름도 이 제한을 만족해야 한다.

폴더 전송은 정션·심볼릭 링크 등 재분석 지점을 건너뛴다. 상태창에는 현재
항목과 다음 4개, 원본 크기, 경과 시간과 누적 완료·실패·대기 수를 표시하지만
신뢰할 수 없는 퍼센트와 남은 시간은 표시하지 않는다. 전송 중 Scrcpy 창,
기기 연결 또는 DX Manager가 종료되면 현재 전송을 취소하고 임시 파일·staging
폴더 정리를 시도한다. 이미 기기 연결이 사라졌다면 정리가 실패해 로그만 남을
수 있다.

설정에서 관리형 전송을 끄면 새로 여는 DeX·단일창부터 순정 Scrcpy 파일
드롭을 사용한다. 이미 실행 중인 창의 환경 변수는 바뀌지 않는다. 순정 방식은
일부 Windows 환경에서 한글 등 비ASCII 로컬 파일명을 보존하지 못할 수 있다.

## 앱별 보안 및 다중 디스플레이 제한

일부 금융·게임·스트리밍 앱은 USB 디버깅 또는 개발자 옵션 활성 상태를
감지해 실행을 거부한다. 보호된 화면과 DRM 콘텐츠는 Scrcpy에서 검게 보이거나
캡처가 차단될 수 있으며, 가상·보조 디스플레이 실행 자체를 거부하는 앱도
있다. 이러한 앱 및 Android 보안 정책은 우회하지 않는다.

다중 디스플레이를 완전히 지원하지 않거나 기존 휴대폰 task를 재사용하는 앱은
DeX에서 시작해도 휴대폰 화면에서 열릴 수 있다. 선택 앱 강제 종료가 일부
경우에 도움이 되지만, 앱 자체 정책까지 강제로 변경할 수는 없다.

## Android 정리 앱 권한 부여

공식 DX Companion이 설치된 경우에만 진단 페이지에서 권한을 부여할 수 있다.
번들 설치 기능은 정확한 APK SHA-256과 v2 서명 인증서를 먼저 검사하고 현재
선택된 ADB 기기에만 설치한다. 설치 후에도 `base.apk`의 서명, package와 버전을
다시 확인한다. 패키지 누락·서명 불일치·ADB 미승인 상태에서는 설치 또는 권한
버튼을 비활성화하며 다른 서명의 같은 패키지에는 권한을 부여하지 않는다.
권한 부여 직전과 직후에도 다시 검사하고 사후 검증이 실패하면 즉시 회수한다.

Companion은 Android의 단일 전역 `overlay_display_devices` 설정을 삭제하므로,
DX Manager가 만든 화면과 사용자가 개발자 옵션에서 직접 선택한 보조
디스플레이를 구분할 수 없다. 정리하면 현재 설정된 시뮬레이션 화면이 모두
제거된다. 앱을 삭제한 뒤 다시 설치하면 권한도 사라져 다시 부여해야 한다.
개발자 옵션의 절전모드 해제를 끄는 기능도 제공하며, 타일과 위젯의 기본
동작은 두 항목을 함께 정리하는 것이다.

## 배포

- 설치 프로그램 없음
- Assembly/File version은 `2.0.0.0`
- 앱 아이콘, 제작자/GitHub 링크, MIT 라이선스와 제3자 고지 완료
- README, 사용 설명서와 FAQ의 한국어/영어 스크린샷 배치 완료
- 공개 ZIP에서 개인 설정, PDB, 로그와 테스트 스크린샷 제외 확인
- 자동화 테스트 없이 주요 흐름은 실기 테스트에 의존

## macOS 포터블 서명과 실기 범위

### 2026-10-12 follow-up / 후속 확인

A follow-up of the published arm64 build on USB SM-S942N (Android 17, SDK 37,
One UI property `90000`) kept DeX visible with the phone panel off, as confirmed
by the user. This is not evidence of a fix for Galaxy Z Flip6, manual locking,
or other models/firmware. Preview.2 code checks passed (Release build without
warnings/errors, xUnit 121/121, multi-device 39/39). Both preview.2 ZIPs passed
package checks, and native arm64 noninteractive launcher checks passed. The
preview.2 interactive launcher started DeX on authorized USB SM-S942N and
panel OFF was observed. `O` displayed help without changing the scrcpy
process, overlay, or panel state. External settings paths and the app signature
were verified after startup. The user confirmed native screen-on/off and normal
DeX display. `2` after ON → OFF restored the panel and baseline settings; a
second DeX start followed by active-session `Q` exited with code 0, restored
the same baseline, and left no DX Manager/scrcpy processes. The app signature
remained valid after exit. These results apply only to this USB SM-S942N;
folding/manual locking, Galaxy Z Flip6, and other models/firmware remain untested.
Empty macOS USB inventory output did not reflect the authorized USB ADB
connection in this environment; it alone is not evidence of disconnection.
TUI `O` only shows shortcut help; focus the intended scrcpy window and use left
`Option+O` for off or `Option+Shift+O` for on. Preview.1's separate helper was
removed after source review found that its startup flag did not establish
restoration after native screen-on. This sequence was not reproduced on a
physical phone; see `DECISIONS.md`.

The candidate `.app` remains ad hoc signed, and embedded components may still
need approval. In macOS 15 and later, use **System Settings > Privacy & Security
> Open Anyway** after attempting launch; Control-click is no longer a
Gatekeeper override. See [Apple's notice](https://developer.apple.com/news/?id=saqachfa).

The older preview.1 arm64 app ran through its internal launcher on macOS 26.6.2.
Its two ZIPs passed static package checks, but x64 was cross-packaged without
Intel or Rosetta execution. Those results do not validate preview.2 artifacts.
The visual Finder-to-Terminal flow and quarantined-download approval have not
been verified for either candidate.

공개 arm64 빌드를 USB SM-S942N 한 대(Android 17, SDK 37, One UI 속성
`90000`)에서 후속 확인한 결과, 사용자가 패널이 꺼진 상태의 DeX 정상 표시를
확인했다. Galaxy Z Flip6, 수동 잠금, 다른 모델·펌웨어가 수정됐다는 근거는 아니다.
preview.2 코드 검증은 Release 경고·오류 0, xUnit 121/121·다중 기기 39/39로
통과했다. 두 ZIP의 패키지 검사와 네이티브 arm64 비대화형 실행기를 확인했다.
preview.2 대화형 실행기에서 authorized USB SM-S942N의 DeX를 시작해 패널 OFF를
관찰했다. `O`는 안내만 표시했고 scrcpy 프로세스·overlay·패널 상태는 유지됐다.
실행 후 번들 밖 설정 경로와 앱 서명도 확인했다. 사용자가 화면 켜기·끄기 단축키와
DeX 정상 표시를 확인했다. ON → OFF 뒤 `2`로 중지해 패널·기존 설정이 복원됐고,
DeX 재시작 후 실행 중 `Q`로 종료하여 코드 0·같은 원래 상태 복원·관련 프로세스가
남지 않음을 확인했다. 종료 후 앱 서명도 유효했다. 이 결과는 해당 USB SM-S942N에
한정하며 접기·수동 잠금, Galaxy Z Flip6와 다른 모델·펌웨어는 미확인이다. 이 환경의 빈
macOS USB 목록은 실제 authorized USB ADB 연결을 반영하지 않았으므로 단독으로
연결 해제의 근거가 되지 않는다. TUI `O`는 단축키 안내만 표시하며 대상 scrcpy 창에서 왼쪽 `Option+O`로
끄고 `Option+Shift+O`로 켠다. preview.1의 별도 helper는 화면 켜기 이후 복원을
시작 옵션으로 확인할 수 없다는 소스 검토에 따라 제거했다. 이 순서를 실제 휴대폰에서
실패로 재현한 것은 아니며 이유는 `DECISIONS.md`를 참조한다.

후보 `.app`도 ad hoc 서명만 사용하며 내부 구성요소의 승인이 추가로 필요할 수
있다. macOS 15 이상에서는 실행을 시도한 뒤 **시스템 설정 > 개인정보 보호 및
보안 > 그래도 열기**를 사용한다. Control-클릭은 Gatekeeper 승인 방법이
아니다. [Apple 변경 안내](https://developer.apple.com/news/?id=saqachfa)를 참조한다.

이전 preview.1 arm64 앱은 macOS 26.6.2에서 내부 실행기로 기동했다. 그 ZIP
두 개는 정적 패키지 검증을 통과했지만 x64는 교차 패키징했으며 Intel·Rosetta에서
실행하지 않았다. 해당 결과가 preview.2 산출물을 검증하는 것은 아니다. 두 후보
모두 Finder에서 Terminal이 열리는 화면과 quarantine 다운로드의 최초 승인은
미확인이다.

macOS arm64/x64 ZIP은 self-contained이므로 Homebrew와 별도 .NET 설치에
의존하지 않는다. 다만 현재 자동화 설정에는 Apple Developer ID 인증서와
notarization 자격 증명이 구성되어 있지 않다. 브라우저로 받은 ZIP은 최초 실행
시 Gatekeeper 승인이 필요할 수 있으며, 서명·공증 전에는 모든 macOS
버전에서 경고 없는 최초 실행을 보장하지 않는다. 패키징 스크립트가 quarantine
속성을 자동 삭제하거나 macOS 보안 기능을 우회하지 않는다.

이전 포터블 빌드에서는 Apple Silicon 네이티브 기동과 Intel ZIP의 Rosetta 기동을
확인한 기록이 있다. 이 기록은 `2.0.2-preview.1`이나 `2.0.2-preview.2` 후보의
x64 실행 결과를 대신하지 않는다. 실제 Intel Mac의 전체 Galaxy DeX 흐름도
별도 확인 대상이다.
