# DX Manager work and release workflow

## English — current 2026-10-16

1. Read repository AGENTS, docs/README, HANDOFF, PROJECT_BRIEF, SESSION and TODO; inspect Git state.
2. Work only in the approved portable checkout. Preserve accepted changes and user data; Store is read-only here.
3. Diagnosis/conversation requests do not authorize product edits. Documentation requests authorize local documentation.
4. Antivirus results are not deployment approval. Wait for the maintainer's explicit instruction to publish.
   Commit/push/tag/release creation and remote page edits each stay within that authorized scope.

### Build and verification

Windows: .NET Framework 4.6.2, x64 Release, VS2019 MSBuild/reference assemblies. Build from the solution
root with the verified shared Companion component present. See [Building](BUILDING.md) for the external
component requirement and the standalone public-source release gate.

```powershell
.\scripts\Verify-OfficialBuild.ps1
```

The approved workspace verifier builds and runs actual-assembly regression/UI fixtures, using the
product executable config. Device commands are blocked in fixtures. New device/Windows-shutdown/OS
behavior is not considered physically verified solely because these checks pass.

### Canonical Android component

Edit/build only `E:\vs\DX Companion Shared\source`. Read that component's AGENTS/README/CHANGELOG/release.json.
Record workroom, exact chat/thread, changed files, version and results. Use the existing trusted signing
input; do not copy keys/passwords. Run unit tests/lint/signed Release and verify identity/certificate/hash.
The portable wrappers delegate to the shared build. Never restore the archived per-product Android tree
as an independently maintained source. Never bundle the private AI test APK.

### Preview and final package

- `Build-PortablePreview.ps1`: overwrite the fixed DX Manager Preview folder, preserving user state.
- `Build-FinalRelease.ps1`: back up the previous final outside dist, then create the clean DX Manager v2.5.0 folder.
- `Package-Release.ps1`: copy an explicit runtime/license list and a short README. `-NoArchive` suppresses ZIP;
  `-SkipBuild` requires verified output. User-requested upload ZIPs must match the recorded39-file final manifest.

All final user artifacts belong in `E:\vs\dex system\dist`. Do not create per-preview version folders or
archives. Do not ship config/settings.json, onboarding.json, update-check.json, logs, captures, received
files, PDBs, signing inputs, test programs or source documentation/images. Keep required licenses and the
original scrcpy runtime images. Do not delete user data while cleaning a package.

### Documentation, screenshots and publication

- README/full guides/FAQ/current technical notes must describe the actual 2.5.0 behavior and menu names.
- Keep historical release facts and license text. Preserve remote macOS work missing from this local branch.
- Use verified current portable screenshots; do not label Store or fixture/mock captures as real portable use.
- GitHub documentation is not copied into the binary ZIP. An embedded-help edit needs a new EXE and renewed checks;
  a GitHub-only document edit does not justify replacing the already scanned binary.
- Before publication, close [the documentation audit](DOCUMENTATION_AUDIT_2026-10-16.md) items: current screenshots,
  public shared-component dependency, relative links/anchors, exact checksums and remote-main reconciliation.
- Publish only after an explicit maintainer instruction. The message “all antivirus checks are clean” is a test
  result, not such an instruction. Do not infer approval or ask for a redundant one after a real instruction.

## 한국어

포터블 작업선·Store·개인 테스트판을 분리하고 사용자 변경·설정·원본 APK를 보존합니다.
현재 기준은 Windows용 2.5.0 / scrcpy 5.0.1 / 공용 Companion 2.1.6입니다.
제품 변경 시 관련 검증, Android 변경 시 공용 소스의 버전·서명·작업방 기록 절차를 따릅니다.
고정 프리뷰는 덮어쓰고 최종 배포 폴더와 업로드 ZIP에는 개인 데이터나 개발 파일을 넣지 않습니다.

문서와 촬영 자료는 로컬에서 준비합니다. 검사 결과 공유만으로 배포를 시작하지 않습니다.
메이님이 배포를 직접 지시하기 전에는 커밋·푸시·태그·릴리스 생성·원격 문서 변경을 하지 않습니다.
