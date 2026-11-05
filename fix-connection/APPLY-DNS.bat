@echo off
setlocal
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios de Administrador...
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo ========================================================
echo   Configurando DNS Estatico no Wi-Fi (1.1.1.1 / 8.8.8.8)
echo ========================================================
echo.

netsh interface ip set dns name="Wi-Fi" static 1.1.1.1
netsh interface ip add dns name="Wi-Fi" 8.8.8.8 index=2
ipconfig /flushdns

echo.
echo ========================================================
echo [OK] Servidores DNS configurados com sucesso!
echo ========================================================
echo.
netsh interface ip show dns "Wi-Fi"
echo.
echo Concluido! Pode fechar esta janela.
pause
