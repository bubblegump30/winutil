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

$powerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

if (-not (Test-WinUtilAdministrator)) {
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

    # Run WinUtil in a clean Windows PowerShell process. This intentionally
    # mirrors the supported `irm https://christitus.com/win | iex` launch path
    # and prevents this launcher's StrictMode/session state from leaking into
    # the downloaded WinUtil script.
    $command = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-RestMethod -Uri '$launcherUrl' -UseBasicParsing | Invoke-Expression"

    & $powerShellExe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command $command
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "WinUtil exited with code $exitCode."
    }
}
catch {
    Write-Host ''
    Write-Host 'WinUtil failed to start.' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ''
    Write-Host 'The launcher reached WinUtil, but the WinUtil process returned an error.' -ForegroundColor Yellow
    Pause-WinUtilLauncher
    exit 1
}
