param([Parameter(Mandatory = $true)][string]$ArchivePath)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Windows-Portable-Common.ps1')
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('dxm-win-guards-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
try {
    # Validate before extracting a second copy for deliberately modified fixtures.
    & (Join-Path $PSScriptRoot 'Verify-WindowsPackage.ps1') -ArchivePath $ArchivePath -SkipExecution
    [IO.Compression.ZipFile]::ExtractToDirectory([IO.Path]::GetFullPath($ArchivePath), $scratch)
    $package = Join-Path $scratch 'DX Manager'
    foreach ($relative in @(
        'config/settings.json', 'tools/unapproved.apk', 'tools/debug.pdb',
        'tools/signing.properties', 'tools/private.key', 'tools/runtime.log'
    )) {
        $path = Join-Path $package $relative
        if (Test-Path -LiteralPath $path) { throw "Test fixture would replace an existing file: $relative" }
        [IO.File]::WriteAllText($path, 'Generated package guard test only.')
        $rejected = $false
        try { Assert-DxmPortableContents $package }
        catch { $rejected = $true }
        finally { Remove-Item -LiteralPath $path -Force }
        if (!$rejected) { throw "Package guard accepted a forbidden file: $relative" }
        Write-Host "Package guard rejected: $relative"
    }
    foreach ($relative in @('tools/companion/DX-Companion.apk', 'tools/loopback/dxm-loopback.jar')) {
        $path = Join-Path $package $relative
        $original = [IO.File]::ReadAllBytes($path)
        [IO.File]::WriteAllBytes($path, [byte[]](0, 1, 2, 3))
        $rejected = $false
        try { Assert-DxmPortableContents $package }
        catch { $rejected = $true }
        finally { [IO.File]::WriteAllBytes($path, $original) }
        if (!$rejected) { throw "Package guard accepted a modified artifact: $relative" }
        Write-Host "Package guard rejected a modified artifact: $relative"
    }
    $required = Join-Path $package 'tools/companion/DX-Companion.apk'
    $original = [IO.File]::ReadAllBytes($required)
    Remove-Item -LiteralPath $required -Force
    $rejected = $false
    try { Assert-DxmPortableContents $package }
    catch { $rejected = $true }
    finally { [IO.File]::WriteAllBytes($required, $original) }
    if (!$rejected) { throw 'Package guard accepted a missing Companion APK.' }
    Assert-DxmPortableContents $package
    Write-Host 'Nine negative package guard cases and the restored clean fixture passed.'
}
finally {
    Remove-Item -LiteralPath $scratch -Force -Recurse
}
