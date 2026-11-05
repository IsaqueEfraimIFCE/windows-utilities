@echo off
:: Request administrator privileges if not running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo ======================================================
echo   Restoring Default Watermark / Service Settings
echo ======================================================
echo.

:: Re-enable svsvc service (3 = Demand / Manual start)
echo [1/2] Re-enabling watermark notification service...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\svsvc" /v "Start" /t REG_DWORD /d 3 /f >nul
net start svsvc >nul 2>&1

:: Restart Windows Explorer to apply changes
echo [2/2] Restarting Windows Explorer...
taskkill /f /im explorer.exe >nul
start explorer.exe

echo.
echo ======================================================
echo   Done! Default settings restored.
echo ======================================================
pause
