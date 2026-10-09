[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-WinUtilAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-WinUtilLauncherError {
    param([Parameter(Mandatory)][string]$Message)

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [void][System.Windows.Forms.MessageBox]::Show(
            $Message,
            'WinUtil Launcher',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
    catch {
        # The launcher intentionally has no visible console. If MessageBox
        # initialization also fails, there is no secondary UI to display.
    }
}

$powerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

if (-not (Test-WinUtilAdministrator)) {
    $quotedScriptPath = '"{0}"' -f $PSCommandPath
    $argumentLine = "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File $quotedScriptPath"

    try {
        Start-Process -FilePath $powerShellExe -ArgumentList $argumentLine -Verb RunAs -WindowStyle Hidden | Out-Null
        exit 0
    }
    catch {
        Show-WinUtilLauncherError "WinUtil could not request Administrator access.`r`n`r`n$($_.Exception.Message)"
        exit 1
    }
}

$launcherUrl = 'https://christitus.com/win'

try {
    # WinUtil runs in a clean Windows PowerShell process so this launcher's
    # StrictMode/session state cannot leak into the downloaded script. The
    # console is hidden while WinUtil's WPF interface remains visible.
    $command = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-RestMethod -Uri '$launcherUrl' -UseBasicParsing | Invoke-Expression"
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $argumentLine = "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $encodedCommand"

    $process = Start-Process -FilePath $powerShellExe -ArgumentList $argumentLine -WindowStyle Hidden -Wait -PassThru

    if ($process.ExitCode -ne 0) {
        throw "WinUtil exited with code $($process.ExitCode)."
    }
}
catch {
    Show-WinUtilLauncherError "WinUtil failed to start.`r`n`r`n$($_.Exception.Message)"
    exit 1
}
