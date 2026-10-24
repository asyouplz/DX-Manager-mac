# Screenshots for DX Manager 2.5.0

## English summary

Local preparation only. Use real current portable2.5.0 captures; no remote upload or binary rebuild.
The nine Store manual screenshots supplied by the maintainer were inspected. They show WinUI Store
layouts/labels/icons rather than this portable build, so none is approved unchanged as a 2.5.0 portable
app screenshot. Six existing Android system-setting examples can remain as platform illustrations.
The17 older DX Manager/Companion app images remain on disk for history but are detached from current
instructions until matching current captures are supplied.

## 한국어: 우선 찍을 화면

원본 위치: `E:\vs\소스\스토어판 매뉴얼용 스샷`.
9장을 모두 확인했다. 한글·영문 메인/단일창/전체 화면에는 Store의 카드 설명·메뉴 아이콘·검은 버튼 글자가
남아 있고, 도움말에는 다른 아이콘과 Store 전용 문구가 있다. 영문 다크도 Store 출처이므로 포터블과
동일 화면으로 확인하기 전에는 그대로 사용하지 않는다. 합성으로 프로그램 창을 바꿔 끼우지 않는다.

**README용은 아래 첫 세 종류부터 준비하면 된다. 모든 예전 이미지마다 별도로 찍을 필요는 없다.**

| 우선순위 | 촬영 내용 | 언어/테마 | 저장할 이름 예시 / 활용 |
| --- | --- | --- | --- |
| 필수 | 실제 DeX 실행 + 포터블 메인 + 미니바가 함께 보이는 전체 화면 | 영어·한국어, 밝음 | `readme-hero-en.png`, `readme-hero-ko.png`; 실행 소개에도 사용 |
| 필수 | 시작 앱이 선택된 단일창1 실행, 앱 창과 포터블 메인 함께 | 영어·한국어, 밝음 | `readme-single-window-en.png`, `readme-single-window-ko.png` |
| 권장 | 연결된 휴대폰을 표시한 메인창 | 영어 또는 한국어, 다크 | `readme-main-dark-en.png` 또는 `readme-main-dark-ko.png` |
| 설명서 | 메인 대기 상태, 일반 설정 | 두 언어가 있으면 각각, 밝음 | `guide-device-connected-*.png`, `guide-settings-basic-*.png` |
| 설명서 | 설정 > 연결, USB·무선·페어링 항목 | 가능한 언어, 승인된 실제 기기 | `guide-device-selection-v2-*.png` |
| 설명서 | 설정 > Companion, 정식2.1.6 상태와 관리 버튼 | 가능한 언어 | `guide-companion-settings-*.png` |
| 설명서 | 설정 > 진단, 환경 검사에 scrcpy 5.0.1 / 기기 정보 | 가능한 언어 | `guide-diagnostics-*.png`; 필요하면 고급 펼친 화면 별도 |
| 설명서 | 도움말 첫 사용 항목 | 영어·한국어 | `guide-help-*.png` |
| 선택 | 실제 PC→휴대폰·휴대폰→PC 전송창 | 밝음/다크 중 대표 화면 | `guide-transfer-*.png` |
| 설명서 | 정식 Companion 2.1.6 홈·빠른 설정·파일 전송 | 휴대폰에서 가능한 언어 | 기존 `guide-companion-home`, `quick-settings`, `file-transfer` 교체 |

`*`는 `en` 또는 `ko`다. 먼저 사진을 원래 이름으로 전달해도 된다. 내용과 사용 위치를 확인한 뒤 저장소의
`docs/images/en`, `docs/images/ko`에 배치한다. 영어 화면을 한글 문서에 쓸 경우 캡션에서 언어를 밝힌다.

### 촬영 기준

- `DX Manager v2.5.0` 최종 폴더의 실제 프로그램을 사용하고 Store/AI 테스트판과 구분한다.
- 배포 ZIP과 검사 완료 EXE/APK를 재빌드하거나 바꾸지 않는다.
- 확인되지 않은 연결 상태를 꾸미거나 테스트 fixture의 가짜 기기/세션을 실제 사용 화면으로 쓰지 않는다.
- 영문/한글은 같은 장면·비슷한 창 크기로 찍으면 보기 쉽다. 바탕화면/Android 앱 내용은 단순한 화면을 쓴다.
- 페어링 코드·인증 토큰·개인 파일 경로/대화 내용이 노출되지 않게 화면을 준비한다.
- 앱 캡처가 준비될 때까지 기존 파일은 삭제하지 않는다. 현재 안내에서는 오래된 앱 이미지 링크만 제외했다.
- 촬영 이미지는 GitHub 문서용이며 사용자 배포 ZIP에 다시 넣지 않는다.

## Store 원본별 판단

| 제공 원본 | 판단 | 근거 |
| --- | --- | --- |
| 메인 한글.png | 재촬영 | Store 카드 설명, 메뉴 아이콘, 준비 문구 및 버튼 글자색 차이 |
| 단일창 한글.png | 재촬영 | Store 단일창 표시·프로필 버튼·설명·아이콘 차이 |
| 도움말 한글.png | 재촬영 | Store판 문구와 문서·연결 아이콘 차이 |
| 전체 한글.png | 재촬영 | DeX 배경은 참고 가능하지만 포함된 관리자 창이 Store UI |
| 영문/메인 영어.png | 재촬영 | 영문 Store 명칭·설명·버튼 차이 |
| 영문/단일창 영어.png | 재촬영 | Store UI가 포함된 실제 실행 장면 |
| 영문/도움말 영어.png | 재촬영 | 메뉴·아이콘·강조 상자 차이 |
| 영문/전체 영어.png | 재촬영 | Store 관리자 창을 포함한 실행 장면 |
| 영문/메인 다크.png | 현재 포터블로 재촬영 | 비교용으로 유용하지만 Store 출처·글꼴/상태/컨트롤 차이 존재 |

## 기존 저장소 이미지23개

### 유지할 Android 설정 예시6개

- `images/en/usb-debugging-rsa-en.png`, `images/ko/usb-debugging-rsa-ko.png`
- `images/en/simulate-secondary-display-en.png`, `images/ko/simulate-secondary-display-ko.png`
- `images/en/simulate-secondary-display-options-en.png`, `images/ko/simulate-secondary-display-options-ko.png`

이들은 DX Manager UI가 아닌 Android 승인·개발자 옵션 예시다. 기기/Android 버전에 따라 모양이 다를 수 있다는
캡션을 사용한다. 최신 실제 폰 화면을 찍을 때 함께 갱신할 수 있지만 Windows UI 변경만으로 무효가 되지는 않는다.

### 교체할 앱 화면17개

- EN: `readme-hero`, `guide-settings-basic`, `guide-diagnostics`, `guide-dex-running`,
  `guide-device-connected`, `guide-device-selection-v2`, `guide-device-diagnostics-v2`,
  `guide-companion-home`, `guide-companion-quick-settings`, `guide-companion-file-transfer`.
- KO: `readme-hero`, `readme-single-window`, `guide-settings-basic`, `guide-diagnostics`,
  `guide-dex-running`, `guide-device-connected`, `guide-advanced-options`.

실제 파일에는 언어 접미사와 `.png`가 붙는다. 일부는 같은 신규 촬영 장면을 재사용하거나 설명을 텍스트로
대체할 수 있다. 새 이미지가 준비되면 README·가이드 참조와 캡션, 해상도·개인정보·링크를 다시 확인한다.
