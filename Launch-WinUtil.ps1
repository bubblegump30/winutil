[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSCommandPath
$compileScript = Join-Path $repoRoot 'Compile.ps1'

function Test-WinUtilAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-WinUtilAdministrator)) {
    $powerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $arguments = @(
        '-NoLogo'
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        ('"{0}"' -f $PSCommandPath)
    )

    Write-Host 'WinUtil requires Administrator access. Requesting elevation...'
    Start-Process -FilePath $powerShellExe -ArgumentList $arguments -WorkingDirectory $repoRoot -Verb RunAs | Out-Null
    exit 0
}

if (-not (Test-Path -LiteralPath $compileScript -PathType Leaf)) {
    throw "Compile.ps1 was not found at '$compileScript'. Keep Launch-WinUtil.ps1 in the WinUtil repository root."
}

Set-Location -LiteralPath $repoRoot

Write-Host 'Building and launching the local WinUtil checkout...'
& $compileScript -Run
