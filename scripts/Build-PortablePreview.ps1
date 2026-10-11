param([switch]$SkipBuild)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$dist=[IO.Path]::GetFullPath('E:\vs\dex system\dist')
$preview=[IO.Path]::GetFullPath((Join-Path $dist 'DX Manager Preview'))
$stageRoot=Join-Path $repo '.build-tools\preview-staging'
$stage=Join-Path $stageRoot 'payload'
function Assert-PreviewPath([string]$relative) {
    if([string]::IsNullOrWhiteSpace($relative) -or [IO.Path]::IsPathRooted($relative)){throw 'Invalid preview manifest path'}
    $absolute=[IO.Path]::GetFullPath((Join-Path $preview $relative))
    if(!$absolute.StartsWith($preview.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Preview path escapes the fixed folder'}
    if($relative -match '^(config|logs|screenshot|receive)[\\/]') {throw 'User data cannot be managed or deleted by the preview manifest'}
    return $absolute
}
foreach($process in Get-Process -Name DXManager -ErrorAction SilentlyContinue) {
    if($process.Path -and [IO.Path]::GetFullPath($process.Path).Equals((Join-Path $preview 'DXManager.exe'),[StringComparison]::OrdinalIgnoreCase)) {
        throw 'The fixed preview is running. Exit it from the tray before rebuilding.'
    }
}
$parameters=@{NoArchive=$true;Version='2.5.0-preview';OutputRoot=$stageRoot;PackageDirectoryName='payload'}
if($SkipBuild){$parameters.SkipBuild=$true}
& (Join-Path $PSScriptRoot 'Package-Release.ps1') @parameters

New-Item -ItemType Directory -Path $preview -Force | Out-Null
if((Get-Item -LiteralPath $preview).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Preview folder must not be a reparse point'}
if(@(Get-ChildItem -LiteralPath $preview -Recurse -Attributes ReparsePoint).Count){throw 'Preview payload must not contain reparse points'}
$managed=@(Get-ChildItem -LiteralPath $stage -Recurse -File | ForEach-Object {$_.FullName.Substring($stage.Length+1)} | Where-Object {$_ -notmatch '^(config|logs|screenshot|receive)[\\/]'} )
$manifest=Join-Path $preview 'preview-files.json'
if(Test-Path -LiteralPath $manifest) {
    $previous=[IO.File]::ReadAllText($manifest) | ConvertFrom-Json
    foreach($relative in $previous.Files) {
        $target=Assert-PreviewPath $relative
        if($relative -notin $managed -and (Test-Path -LiteralPath $target -PathType Leaf)){Remove-Item -LiteralPath $target -Force}
    }
}
foreach($relative in $managed) {
    $target=Assert-PreviewPath $relative
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($target)) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $stage $relative) -Destination $target -Force
}
$configDir=Join-Path $preview 'config'; New-Item -ItemType Directory -Path $configDir -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $stage 'config\README.txt') -Destination $configDir -Force
[IO.File]::WriteAllText($manifest,([pscustomobject]@{Folder='DX Manager Preview';Files=$managed} | ConvertTo-Json -Depth 4),[Text.UTF8Encoding]::new($true))
Write-Host "Fixed preview: $preview"
Write-Host 'Existing settings, acknowledgement, logs and captures were preserved. No ZIP created.'