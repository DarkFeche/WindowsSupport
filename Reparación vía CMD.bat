.
echo on
msg /time:3 * "Reparador de Windows iniciado..."
cd /D %WINDIR%\
rmdir /s /q SoftwareDistribution
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /RestoreHealth
DISM /Online /Cleanup-Image /RestoreHealth /Source:"H:\CD" /LimitAccess
DISM /online /cleanup-image /startcomponentcleanup
sfc /scannow
msg * "¡Reparación completada!"
msg /time:10 * "Si el problema persiste, volver a ejecutar este archivo iniciando la pc en MODO SEGURO CON FUNCIONES DE RED"
