param([switch]$SkipBuild,[string]$SigningPropertiesPath,
 [string]$ChangeSummary='Build and verify the shared official Companion.')
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$shared=[IO.Path]::GetFullPath((Join-Path $repo '..\DX Companion Shared'))
if(!$SkipBuild){& (Join-Path $PSScriptRoot 'Build-AndroidCleanup.ps1') -SigningPropertiesPath $SigningPropertiesPath -ChangeSummary $ChangeSummary}
& (Join-Path $shared 'Verify-Companion.ps1')
Get-Item -LiteralPath (Join-Path $shared 'release\DX-Companion.apk')|Select-Object FullName,Length