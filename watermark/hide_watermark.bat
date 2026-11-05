@echo off
:: Request administrator privileges if not running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo ======================================================
echo   Hiding Windows Activation Watermark
echo ======================================================
echo.

:: 1. Disable the notification service responsible for the watermark
echo [1/3] Disabling watermark notification service...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\svsvc" /v "Start" /t REG_DWORD /d 4 /f >nul
net stop svsvc >nul 2>&1

:: 2. Ensure desktop paint version watermark is turned off
echo [2/3] Setting desktop version paint flag to 0...
reg add "HKCU\Control Panel\Desktop" /v "PaintDesktopVersion" /t REG_DWORD /d 0 /f >nul

:: 3. Restart Windows Explorer to apply changes immediately
echo [3/3] Restarting Windows Explorer...
taskkill /f /im explorer.exe >nul
start explorer.exe

echo.
echo ======================================================
echo   Done! The watermark should now be hidden.
echo   If it still persists, restart your computer.
echo ======================================================
pause
