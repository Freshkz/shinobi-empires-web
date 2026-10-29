@echo off
rem Doble clic: sube el build actual del juego como version nueva a la pagina web.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publicar_juego.ps1" %*
echo.
pause
