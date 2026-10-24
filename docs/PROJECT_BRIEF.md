# DX Manager project brief

## 2026-10-19 portable 120 FPS preparation

The maintainer authorized implementing the Store handoff in the portable product
and rebuilding the fixed preview/final ZIP locally. Store is read-only; reference
commit11050e7822c43ec409d7d943ece5d9884d997b99 is not merged.
Added default60/experimental120, one fail-closed warning before every120 start,
exact screen-off preference restoration, per-phone mixed-session screen policy
and local version-scoped change notes. scrcpy5.0.1 and signed Companion2.1.6 are
unchanged. No AI app detection, Android changes, commit/push/tag or publication.
See PORTABLE_120FPS_2026-10-19.md for implementation and fresh verification.
October16 scan evidence remains historical; the new EXE needs a fresh user scan.


## Current baseline — 2026-10-16

- Product: Windows DX Manager 2.5.0, C# WinForms/.NET Framework 4.6.2 x64.
- Intended Windows range: 7 SP1, 8.1, 10 and 11; Windows 7/8.1 use the bundled legacy ADB path.
- Bundled scrcpy: 5.0.1, with `--hwdec=auto` unless explicitly overridden.
- Official shared DX Companion: 2.1.6/code13, Android 13 minimum, existing official certificate/protocol1.
- Latest public Windows release observed on 2026-10-16: 2.0.1. The 2.5.0 build/ZIP is local and not published.
- Current worktree: `E:\vs\dex system-portable-backport`, branch `feature/portable-backport-v2.0.1-20260928`.
- Store product and private AI test worktrees remain separate. No automatic app detection/AI keymaps in this release.

## Purpose

Manage a Samsung DeX virtual display and up to three independent app windows for each connected physical
Galaxy phone. Keep device sessions/settings/transfers isolated and support local/offline Windows use.
The maintainer reported working Android 16/One UI 8.x and S26 Ultra/Android 17/One UI 9 use; device/app restrictions
are documented in the user guides. The separate macOS public-source work is not part of the Windows ZIP.

## Current behavior contracts

- Identify phones using stable physical identity; merge USB/Wi-Fi transports of the same phone.
- New launches prefer authorized USB; live sessions retain their captured serial and are not migrated.
- USB loss stops windows using that transport without immediately restarting them on Wi-Fi.
- DeX and three app slots can coexist. Start-app selection is optional for DeX and required for each app slot.
- Keep device/slot settings and app profiles separate. A missing-app notice belongs to that device/slot.
- Unicode file and folder transfer preserves structure/empty folders and uses collision-safe sibling names.
- PC-to-phone transfer uses the managed ADB proxy only for the selected push path; normal ADB is not intercepted.
- Capture, input correction and mini bars act on the explicit focused/owned session.
- Main-to-tray closes attached manager dialogs; it leaves Android sessions running. Idle auto-hide also minimizes scrcpy.
- Reopening the EXE restores the existing main instance.
- Show first-run consent until acknowledged, then preserve that record outside normal settings reset.
- Check updates once per local day with a background deadline. Offline failure does not loop; manual checks are in About.
- Automatic new-version notices are lower-right nonmodal banners; silent current/offline automatic checks.
- Companion recovery uses a verified authenticated link. In 2.1.6, disconnected and already-clean state stops protection;
  active/unverified settings retain the existing recovery policy. Windows shutdown starts no new ADB helpers.

## Sources, package and verification

- Windows source: `DexManager`, `DexManager.AdbProxy`, `DexManager.MultiDeviceTests`.
- Canonical Android component: `E:\vs\DX Companion Shared`; `DXDisplayCleanup` is a migration notice.
- Standalone public-source dependency setup remains a release gate; see [Building](BUILDING.md).
- User package:39 files, runtime/licenses/short README; no source screenshots, personal settings or saved consent.
- First-run UI and unit/regression evidence:505 Windows checks and 34 Android tests; see
  [verification](VERIFICATION_v2.5.0.md) and [final artifact record](FINAL_250_2026-10-16.md).
- User reported antivirus checks clean. No new executable is produced by the GitHub documentation refresh.

## 한국어 요약

Windows 정식 준비본은2.5.0, scrcpy 5.0.1, 공용 정식 Companion 2.1.6/code13입니다.
2.0.1은 현재 공개된 Windows 기준이며2.5.0은 아직 게시하지 않았습니다.
실제 동작 계약과 제약은 위 목록 및 사용 설명서·FAQ를 따릅니다. Store와 개인 테스트 제품을 섞지 않습니다.
검사 완료 바이너리는 유지하고, 문서·새 스크린샷·공용 소스 의존성 준비 후 메이님의 배포 지시를 기다립니다.
