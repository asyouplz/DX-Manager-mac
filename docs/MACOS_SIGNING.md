# macOS Developer ID signing and notarization

## English

macOS shows **"Apple could not verify 'DX Manager' is free of malware that may
harm your Mac or compromise your privacy"** for any downloaded app that is not
signed with an Apple **Developer ID Application** certificate *and* notarized by
Apple. Ad-hoc signatures (the default build) cannot be notarized. Removing the
warning for every user therefore requires a paid
[Apple Developer Program](https://developer.apple.com/programs/) membership.

The packaging script and the `macOS portable packages` workflow already contain
the complete signing path. It stays inactive until these repository secrets
exist (Settings > Secrets and variables > Actions):

| Secret | Content |
| --- | --- |
| `MACOS_CERTIFICATE_P12_BASE64` | Developer ID Application certificate with private key, exported as `.p12`, then `base64 -i cert.p12` |
| `MACOS_CERTIFICATE_PASSWORD` | Password chosen when exporting the `.p12` |
| `MACOS_SIGNING_IDENTITY` | Optional. Full name, e.g. `Developer ID Application: Name (TEAMID)` |
| `APPLE_API_KEY_P8_BASE64` | App Store Connect API key (`AuthKey_XXXX.p8`, Developer role), base64-encoded |
| `APPLE_API_KEY_ID` | That key's ID |
| `APPLE_API_ISSUER_ID` | The Issuer ID shown on the App Store Connect Keys page |

Steps:

1. Join the Apple Developer Program. In Xcode > Settings > Accounts > Manage
   Certificates, create a **Developer ID Application** certificate, or create
   it at developer.apple.com > Certificates.
2. In Keychain Access, export that certificate with its private key as `.p12`.
3. In App Store Connect > Users and Access > Integrations > App Store Connect API,
   create a key and download its `.p8` file once.
4. Add the six secrets above to `asyouplz/DX-Manager-mac`.
5. Run the workflow manually with version `2.2.x` and **require_notarization**
   checked. Each job signs every executable with the hardened runtime and a
   secure timestamp, submits the whole package to `notarytool`, staples the
   ticket to `DX Manager.app`, and runs `spctl --assess` before uploading.

Local equivalent, after the identity is in your login keychain and
`xcrun notarytool` can use the API key:

```bash
DXM_CODESIGN_IDENTITY="Developer ID Application: Name (TEAMID)" \
DXM_NOTARY_KEY_PATH="$HOME/keys/AuthKey_XXXX.p8" \
DXM_NOTARY_KEY_ID="XXXX" DXM_NOTARY_ISSUER="issuer-uuid" \
scripts/Package-Mac-Release.sh --rid osx-arm64 --version 2.2.1 --include-app
```

`build/macos/DXManager.entitlements` grants only the hardened-runtime exceptions
that self-contained .NET 8 single-file executables need (JIT and loading the
self-extracted runtime libraries). It is applied to `DXManager.Mac` and
`DXMAdbProxy` only. `DXM_HARDENED_RUNTIME=1` applies the same runtime to an
ad-hoc build so the configuration can be tested without a certificate.

Without a Developer ID, a user can still open a trusted download with
System Settings > Privacy & Security > **Open Anyway**, or remove the download
quarantine themselves with `xattr -dr com.apple.quarantine "<extracted folder>"`.
Those are per-Mac user decisions, not a fix for other users.

## 한국어

다운로드한 앱이 Apple **Developer ID Application** 인증서로 서명되고 Apple
**공증**까지 받지 않으면 macOS는 "Apple은 'DX Manager'에 사용자의 Mac에 손상을
입히거나 개인정보에 침입할 수 있는 악성 코드가 없음을 확인할 수 없습니다"라고
표시합니다. 기본 빌드의 ad-hoc 서명은 공증할 수 없으므로, 모든 사용자에게서 이
경고를 없애려면 유료 [Apple Developer Program](https://developer.apple.com/programs/)
가입이 필요합니다.

패키징 스크립트와 워크플로에는 서명·공증 경로가 모두 들어 있으며, 위 표의 저장소
Secret 6개를 등록하면 활성화됩니다. 등록 후 워크플로를 수동 실행하면서
**require_notarization**을 선택하면 모든 실행 파일을 hardened runtime·보안
타임스탬프로 서명하고, 패키지 전체를 공증한 뒤 `DX Manager.app`에 티켓을 붙이고
`spctl` 검사를 통과해야 업로드합니다.

Developer ID가 없는 동안에는 신뢰하는 다운로드에 한해 시스템 설정 > 개인정보 보호
및 보안 > **그래도 열기**를 쓰거나, 사용자가 직접
`xattr -dr com.apple.quarantine "<압축을 푼 폴더>"`로 다운로드 격리 속성을 제거할 수
있습니다. 이는 해당 Mac에서의 사용자 판단이며 다른 사용자에 대한 해결책은 아닙니다.
