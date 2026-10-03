param(
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [string]$ArchivePath = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Windows-Portable-Common.ps1')

# Published by maze-mei, not a rebuilt or re-signed APK. Check the archive before
# reading it, then check the APK against the runtime SHA-256 and v2 signer pins.
# Source: https://github.com/maze-mei/DX-Manager/releases/tag/v2.0.1
$url = 'https://github.com/maze-mei/DX-Manager/releases/download/v2.0.1/DX-Manager-v2.0.1-win-x64.zip'
$archiveSha256 = '5F9C5A6AF6199D38458F6266869DDBACC58722A3A915696FF02935CF8965B2C1'
$output = [IO.Path]::GetFullPath($OutputPath)
if (Test-Path -LiteralPath $output) {
    Assert-DxmCompanionApk $output
    Write-Host "Existing Companion APK is verified: $output"
    return
}
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('dxm-companion-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
try {
    if ([string]::IsNullOrWhiteSpace($ArchivePath)) {
        $archive = Join-Path $scratch 'upstream-v2.0.1.zip'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing
    }
    else {
        $archive = [IO.Path]::GetFullPath($ArchivePath)
    }
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $archiveSha256) {
        throw 'The upstream v2.0.1 ZIP SHA-256 does not match the published release.'
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try {
        $entries = @($zip.Entries | Where-Object {
            $_.FullName.Replace('\', '/') -ceq 'DX Manager/tools/companion/DX-Companion.apk'
        })
        if ($entries.Count -ne 1) {
            throw 'The upstream archive must contain exactly one expected Companion APK entry.'
        }
        $candidate = Join-Path $scratch 'DX-Companion.apk'
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entries[0], $candidate, $false)
    }
    finally { $zip.Dispose() }
    Assert-DxmCompanionApk $candidate
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($output)) -Force | Out-Null
    Copy-Item -LiteralPath $candidate -Destination $output
    Write-Host "Verified original DX Companion 2.0.0 APK: $output"
}
finally {
    # Only this invocation's newly created, explicit temporary directory.
    Remove-Item -LiteralPath $scratch -Force -Recurse
}
