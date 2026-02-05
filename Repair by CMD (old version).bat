@echo on
msg * /time:3 "Reparador de Windows iniciado..."
echo --- Nueva Ejecucion --- >> report.txt

cd /D %WINDIR%
rmdir /s /q SoftwareDistribution | tee -a report.txt

DISM /Online /Cleanup-Image /CheckHealth | tee -a report.txt
DISM /Online /Cleanup-Image /ScanHealth | tee -a report.txt
DISM /Online /Cleanup-Image /RestoreHealth | tee -a report.txt
DISM /Online /Cleanup-Image /RestoreHealth /Source:"H:\CD" /LimitAccess | tee -a report.txt
DISM /Online /Cleanup-Image /StartComponentCleanup | tee -a report.txt
sfc /scannow | tee -a report.txt

msg * /time:2 "Trabajo terminado!"
msg * /time:10 "Si el problema persiste, volver a ejecutar este archivo iniciando la pc en MODO SEGURO CON FUNCIONES DE RED"

notepad report.txt
pause
