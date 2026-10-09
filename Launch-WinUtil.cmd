@echo off
setlocal
cd /d "%~dp0"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launch-WinUtil.ps1"
set "exitCode=%errorlevel%"

if not "%exitCode%"=="0" (
    echo.
    echo WinUtil failed to start. Exit code: %exitCode%
    echo Review the error above, then press any key to close this window.
    pause >nul
)

exit /b %exitCode%
