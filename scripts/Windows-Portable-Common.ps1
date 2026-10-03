# Shared build-time checks. No APK is installed and no phone command is run.
$dxmPortableRepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Get-DxmCompanionPins {
    $source = Get-Content -Raw -LiteralPath (Join-Path $dxmPortableRepoRoot `
        'DexManager/Services/DisplayCleanupPermissionService.cs')
    $apk = [regex]::Match($source, 'ExpectedBundledApkSha256\s*=\s*"([A-Fa-f0-9]{64})"')
    $certificate = [regex]::Match($source, 'ExpectedCertificateSha256\s*=\s*"([A-Fa-f0-9]{64})"')
    if (!$apk.Success -or !$certificate.Success) {
        throw 'The application Companion integrity pins could not be read.'
    }
    return @{ Apk = $apk.Groups[1].Value; Certificate = $certificate.Groups[1].Value }
}

function Assert-DxmCompanionApk([string]$Path) {
    if (!(Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "The signed DX Companion APK is required but missing: $Path"
    }
    $pins = Get-DxmCompanionPins
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $pins.Apk) {
        throw 'The Companion APK is not the exact APK pinned by the application.'
    }
    if (-not ('DxmPortableApkVerifier' -as [type])) {
        $reader = Get-Content -Raw -LiteralPath (Join-Path $dxmPortableRepoRoot `
            'DexManager/Utils/ApkSigningCertificateReader.cs')
        Add-Type -TypeDefinition ($reader + @'

public static class DxmPortableApkVerifier
{
    public static string ReadCertificate(string path)
    {
        return DexManager.Utils.ApkSigningCertificateReader.ReadSingleV2CertificateSha256(path);
    }
}
'@)
    }
    if ([DxmPortableApkVerifier]::ReadCertificate($Path) -ne $pins.Certificate) {
        throw 'The Companion APK v2 signing certificate does not match the application pin.'
    }
}

function Assert-DxmLoopbackHelper([string]$PackageRoot) {
    $jar = Join-Path $PackageRoot 'tools/loopback/dxm-loopback.jar'
    $checksum = ((Get-Content -Raw -LiteralPath "$jar.sha256").Trim() -split '\s+')[0]
    $source = Get-Content -Raw -LiteralPath (Join-Path $dxmPortableRepoRoot `
        'DexManager/Services/LoopbackDexService.cs')
    $match = [regex]::Match($source, 'HelperSha256\s*=\s*"([a-fA-F0-9]{64})"')
    if (!$match.Success -or $checksum -ne $match.Groups[1].Value -or
        (Get-FileHash -LiteralPath $jar -Algorithm SHA256).Hash -ne $checksum) {
        throw 'The loopback helper, checksum and runtime integrity pin must match.'
    }
}

function Assert-DxmPortableContents([string]$PackageRoot) {
    $required = @(
        'DXManager.exe', 'DXManager.exe.config', 'ko/DXManager.resources.dll',
        'config/README.txt', 'README.md', 'LICENSE',
        'docs/USER_GUIDE_EN.md', 'docs/USER_GUIDE_KO.md', 'docs/PHONE_PREVIEW_MODE.md',
        'tools/adb-proxy/DXMAdbProxy.exe', 'tools/companion/DX-Companion.apk',
        'tools/loopback/dxm-loopback.jar', 'tools/loopback/dxm-loopback.jar.sha256',
        'tools/loopback/LICENSE', 'tools/loopback/NOTICE',
        'tools/adb/legacy/adb.exe', 'tools/adb/legacy/AdbWinApi.dll',
        'tools/adb/legacy/AdbWinUsbApi.dll', 'tools/adb/legacy/libwinpthread-1.dll',
        'tools/scrcpy/scrcpy.exe', 'tools/scrcpy/scrcpy-server', 'tools/scrcpy/adb.exe',
        'tools/scrcpy/AdbWinApi.dll', 'tools/scrcpy/AdbWinUsbApi.dll',
        'tools/scrcpy/SDL3.dll', 'tools/scrcpy/avcodec-62.dll',
        'tools/scrcpy/avformat-62.dll', 'tools/scrcpy/avutil-60.dll',
        'tools/scrcpy/swresample-6.dll', 'tools/scrcpy/libusb-1.0.dll',
        'licenses/DX-Manager-MIT-LICENSE.txt', 'licenses/THIRD_PARTY_NOTICES.md',
        'licenses/scrcpy-LICENSE.txt', 'licenses/LGPL-2.1-LICENSE.txt',
        'licenses/MinGW-w64-winpthreads-LICENSE.txt', 'licenses/SDL3-LICENSE.txt',
        'licenses/zlib-LICENSE.txt', 'licenses/dav1d-LICENSE.txt'
    )
    foreach ($relative in $required) {
        if (!(Test-Path -LiteralPath (Join-Path $PackageRoot $relative) -PathType Leaf)) {
            throw "Required portable file is missing: $relative"
        }
    }
    $prefix = [IO.Path]::GetFullPath($PackageRoot).TrimEnd('\', '/') +
        [IO.Path]::DirectorySeparatorChar
    foreach ($entry in (Get-ChildItem -LiteralPath $PackageRoot -Force -Recurse)) {
        $relative = $entry.FullName.Substring($prefix.Length).Replace('\', '/')
        if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Portable packages must not contain links: $relative"
        }
        if ($relative -match '(?i)(^|/)(logs?|screenshots?|captures?|tests?|\.git|\.build-tools)(/|$)' -or
            $entry.Name -match '(?i)(^settings\.json($|\.)|^signing\.properties$|^\.DS_Store$|^\.env($|\.)|\.(pdb|log|tmp|bak|jks|keystore|p12|pfx|pem|key)$)') {
            throw "Runtime, debug or private data must not be packaged: $relative"
        }
        if (!$entry.PSIsContainer -and $entry.Extension -eq '.apk' -and
            $relative -cne 'tools/companion/DX-Companion.apk') {
            throw "Only the verified Companion APK is allowed: $relative"
        }
    }
    Assert-DxmCompanionApk (Join-Path $PackageRoot 'tools/companion/DX-Companion.apk')
    Assert-DxmLoopbackHelper $PackageRoot
}
