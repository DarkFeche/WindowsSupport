<#
.SYNOPSIS
    Script para reparar la imagen de Windows 10 usando DISM y SFC.
    Versión mejorada de un script batch de CMD.
.DESCRIPTION
    Este script debe ejecutarse como Administrador.
    1. Detiene Windows Update y limpia la caché de SoftwareDistribution.
    2. Ejecuta DISM (Check, Scan, Restore).
    3. Busca un medio de instalación en E:\sources (install.wim o install.esd) para usarlo como fuente de reparación.
    4. Ejecuta SFC /scannow.
    5. Guarda un registro completo en C:\Windows\Logs\DISM\
.NOTES
    Autor: Feche (con ayuda de Gemini)
    Fecha: 10/11/2025
#>

# --- 1. VERIFICACIÓN DE PERMISOS ---
Write-Host "Verificando permisos de Administrador..." -ForegroundColor Yellow
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "¡Error de permisos!"
    Write-Warning "Este script debe ejecutarse como Administrador."
    Write-Warning "Hacé clic derecho en el archivo .ps1 -> 'Ejecutar con PowerShell (Administrador)'."
    Read-Host -Prompt "Presiona Enter para salir"
    exit # Salir del script
}
Write-Host "Permisos de Administrador OK." -ForegroundColor Green

# --- 2. CONFIGURACIÓN DEL REGISTRO (LOGGING) ---
# Creamos un archivo de log único en una carpeta segura
$LogFolder = "C:\Windows\Logs\DISM"
if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory
}
$LogFile = Join-Path -Path $LogFolder -ChildPath "SystemRepairLog-$(Get-Date -Format 'yyyyMMdd-HHmm').txt"
Start-Transcript -Path $LogFile
Write-Host "Registro de sesión iniciado en: $LogFile" -ForegroundColor Cyan

# --- 3. INICIO ---
msg.exe * /time:3 "Reparador de Windows (PowerShell) iniciado..."
Write-Host "--- Nueva Ejecución de Reparación ---" -ForegroundColor Yellow

# --- 4. LIMPIEZA DE CACHÉ DE WINDOWS UPDATE ---
Write-Host "Paso 1/5: Limpiando caché de Windows Update (SoftwareDistribution)..." -ForegroundColor Yellow
# Detener servicios para liberar los archivos
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service -Name BITS -Force -ErrorAction SilentlyContinue

# Borrar la carpeta (el -ErrorAction es por si ya no existe)
Remove-Item -Path "$env:WINDIR\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Reiniciando servicios..."
# Reiniciar los servicios
Start-Service -Name wuauserv
Start-Service -Name BITS
Write-Host "Caché de SoftwareDistribution limpiada." -ForegroundColor Green

# --- 5. EJECUCIÓN DE DISM (SIN FUENTE EXTERNA) ---
Write-Host "Paso 2/5: Ejecutando DISM (CheckHealth)..." -ForegroundColor Yellow
DISM.exe /Online /Cleanup-Image /CheckHealth

Write-Host "Paso 3/5: Ejecutando DISM (ScanHealth)..." -ForegroundColor Yellow
DISM.exe /Online /Cleanup-Image /ScanHealth

Write-Host "Paso 4/5: Ejecutando DISM (RestoreHealth desde Windows Update)..." -ForegroundColor Yellow
DISM.exe /Online /Cleanup-Image /RestoreHealth

# --- 6. EJECUCIÓN DE DISM (CON FUENTE LOCAL CORREGIDA) ---
# Buscamos la fuente correcta (WIM o ESD) en E:\sources
$WimSource = "E:\sources\install.wim"
$EsdSource = "E:\sources\install.esd"
$FinalSourcePath = $null

if (Test-Path $WimSource) {
    # Si encontramos install.wim, armamos la ruta
    $FinalSourcePath = "WIM:$WimSource:1" # :1 asume el primer índice (usualmente Windows 10 Pro)
}
elseif (Test-Path $EsdSource) {
    # Si encontramos install.esd, armamos la ruta
    $FinalSourcePath = "ESD:$EsdSource:1"
}

if ($FinalSourcePath) {
    Write-Host "Fuente de reparación local encontrada en E:\ ($FinalSourcePath)" -ForegroundColor Green
    Write-Host "Paso 4b/5: Ejecutando DISM (RestoreHealth desde FUENTE LOCAL)..." -ForegroundColor Yellow
    DISM.exe /Online /Cleanup-Image /RestoreHealth /Source:$FinalSourcePath /LimitAccess
}
else {
    Write-Warning "No se encontró E:\sources\install.wim o E:\sources\install.esd."
    Write-Warning "Se omitirá la reparación con /Source. La reparación anterior (Paso 4) desde Windows Update es la que cuenta."
}

# Limpieza final de componentes
Write-Host "Paso 4c/5: Ejecutando DISM (StartComponentCleanup)..." -ForegroundColor Yellow
DISM.exe /Online /Cleanup-Image /StartComponentCleanup

# --- 7. EJECUCIÓN DE SFC ---
Write-Host "Paso 5/5: Ejecutando sfc /scannow..." -ForegroundColor Yellow
sfc.exe /scannow

# --- 8. FINALIZACIÓN ---
Write-Host "¡Reparación completada!" -ForegroundColor Green
msg.exe * /time:2 "Trabajo terminado!"
msg.exe * /time:10 "Si el problema persiste, volver a ejecutar este archivo iniciando la pc en MODO SEGURO CON FUNCIONES DE RED"

# --- 9. ABRIR REPORTE Y PAUSAR ---
Stop-Transcript # Detener el registro
notepad.exe $LogFile # Abrir el reporte
Read-Host -Prompt "Script finalizado. Presiona Enter para salir"