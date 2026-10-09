@echo off
setlocal
cd /d "%~dp0"

start "" powershell.exe -NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0Launch-WinUtil.ps1"
exit /b 0
