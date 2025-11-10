@echo off
ECHO ========================================================
ECHO Solicitando permisos de Administrador para PowerShell...
ECHO ========================================================

:: --- Inicio del "truco" para auto-elevarse ---
:: 1. Comprueba si ya tiene permisos de admin
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    :: 2. Si no los tiene, usa PowerShell para volver a lanzar este MISMO batch como Admin
    powershell.exe -Command "Start-Process '%~f0' -Verb RunAs"
    GOTO :EOF
)
:: --- Fin del truco ---

:: 3. Si llegaste acá, es porque ya tenés permisos de Administrador
ECHO Permisos de Administrador OK.
ECHO Lanzando el script principal de PowerShell (SystemRepair.ps1)...
ECHO.

:: 4. Llama al script .ps1, permitiendo que se ejecute (Bypass)
:: %~dp0 es una variable mágica que significa "la misma carpeta donde está este .bat"
powershell.exe -ExecutionPolicy Bypass -File "%~dp0\SystemRepair.ps1"

ECHO.
ECHO El script de PowerShell ha terminado.
pause