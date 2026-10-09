[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-WinUtilAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Pause-WinUtilLauncher {
    param([string]$Message = 'Press Enter to close this window')

    try {
        [void](Read-Host $Message)
    }
    catch {
        Start-Sleep -Seconds 8
    }
}

if (-not (Test-WinUtilAdministrator)) {
    $powerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $quotedScriptPath = '"{0}"' -f $PSCommandPath
    $argumentLine = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File $quotedScriptPath"

    try {
        Start-Process -FilePath $powerShellExe -ArgumentList $argumentLine -Verb RunAs | Out-Null
        exit 0
    }
    catch {
        Write-Host ''
        Write-Host 'WinUtil could not request Administrator access.' -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Pause-WinUtilLauncher
        exit 1
    }
}

$launcherUrl = 'https://christitus.com/win'

try {
    Write-Host 'Starting WinUtil...' -ForegroundColor Cyan
    Write-Host "Source: $launcherUrl" -ForegroundColor DarkGray
    Write-Host ''

    # Windows PowerShell 5.1 can otherwise negotiate an older TLS version on
    # some systems. WinUtil is downloaded over HTTPS before execution.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $scriptText = Invoke-RestMethod -Uri $launcherUrl -UseBasicParsing
    if ([string]::IsNullOrWhiteSpace([string]$scriptText)) {
        throw 'The WinUtil download returned an empty response.'
    }

    $scriptBlock = [ScriptBlock]::Create([string]$scriptText)
    & $scriptBlock
}
catch {
    Write-Host ''
    Write-Host 'WinUtil failed to start.' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ''
    Write-Host 'Check your internet connection and make sure christitus.com is reachable.' -ForegroundColor Yellow
    Pause-WinUtilLauncher
    exit 1
}
