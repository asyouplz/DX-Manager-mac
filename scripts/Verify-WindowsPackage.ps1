param(
    [Parameter(Mandatory = $true)][string]$ArchivePath,
    [switch]$SkipExecution
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Windows-Portable-Common.ps1')
$archive = [IO.Path]::GetFullPath($ArchivePath)
$checksumPath = "$archive.sha256"
if (!(Test-Path -LiteralPath $checksumPath -PathType Leaf)) {
    throw "The package checksum file is missing: $checksumPath"
}
$checksumLine = (Get-Content -LiteralPath $checksumPath -Raw).Trim()
$expected = [regex]::Match($checksumLine, '^([a-fA-F0-9]{64})  (.+)$')
if (!$expected.Success -or $expected.Groups[2].Value -cne [IO.Path]::GetFileName($archive) -or
    (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expected.Groups[1].Value) {
    throw 'The package SHA-256 or checksum filename does not match.'
}
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('dxm-win-smoke-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try {
        $seen = @{}
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName.Replace('\', '/')
            if (!$name.StartsWith('DX Manager/', [StringComparison]::Ordinal) -or
                $name -match '(^|/)\.\.(/|$)|:|^/' -or $seen.ContainsKey($name)) {
                throw "Unexpected or duplicate ZIP entry: $name"
            }
            $seen[$name] = $true
        }
    }
    finally { $zip.Dispose() }
    [IO.Compression.ZipFile]::ExtractToDirectory($archive, $scratch)
    $package = Join-Path $scratch 'DX Manager'
    Assert-DxmPortableContents $package
    foreach ($relative in @('DXManager.exe', 'tools/adb-proxy/DXMAdbProxy.exe', 'tools/scrcpy/scrcpy.exe')) {
        $bytes = [IO.File]::ReadAllBytes((Join-Path $package $relative))
        $pe = [BitConverter]::ToInt32($bytes, 0x3c)
        if ($bytes.Length -lt ($pe + 6) -or [BitConverter]::ToUInt32($bytes, $pe) -ne 0x00004550 -or
            [BitConverter]::ToUInt16($bytes, $pe + 4) -ne 0x8664) {
            throw "Expected a Windows x64 executable: $relative"
        }
    }
    if (!$SkipExecution) {
        if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
            throw 'Native Windows smoke checks require Windows. Use -SkipExecution only for structural inspection.'
        }
        foreach ($command in @(
            @{ Path = 'tools/adb-proxy/DXMAdbProxy.exe'; Args = @('--self-test'); Expected = 'self-test passed' },
            @{ Path = 'tools/scrcpy/adb.exe'; Args = @('version'); Expected = 'Android Debug Bridge version' },
            @{ Path = 'tools/adb/legacy/adb.exe'; Args = @('version'); Expected = 'Android Debug Bridge version' },
            @{ Path = 'tools/scrcpy/scrcpy.exe'; Args = @('--version'); Expected = 'scrcpy 4.1' }
        )) {
            $executable = Join-Path $package $command.Path
            $arguments = $command.Args
            $result = (& $executable @arguments 2>&1 | Out-String)
            if ($LASTEXITCODE -ne 0 -or $result -notmatch [regex]::Escape($command.Expected)) {
                throw "Extracted portable command failed: $($command.Path)`n$result"
            }
            Write-Host "Extracted Windows smoke check passed: $($command.Path)"
        }
    }
    else {
        Write-Warning 'Structural checks only: Windows executable startup and phone/GUI behavior were not tested.'
    }
    Write-Host "Portable archive integrity and clean extraction verified: $archive"
    Write-Host 'This does not verify DeX, a physical Galaxy, GUI interaction or Windows 7 behavior.'
}
finally {
    Remove-Item -LiteralPath $scratch -Force -Recurse
}
