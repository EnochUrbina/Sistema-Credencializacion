@echo off
title Tunel Seguro HTTPS para Celular - Hackaton 2026
cls
echo ======================================================================
echo    GENERADOR DE ENLACE PUBLICO HTTPS PARA CELULARES
echo ======================================================================
echo.
echo Conectando con servidor de tunel seguro (SSL)...
echo En unos segundos aparecera un enlace HTTPS (ej. https://xxxx.a.pinggy.link)
echo Puedes abrir ese enlace en tu celular desde cualquier lugar (Wi-Fi o 4G/5G).
echo.
echo IMPORTANTE: El servidor principal (python main.py o INICIAR_SISTEMA.bat)
echo debe estar corriendo al mismo tiempo.
echo.
echo Presiona Ctrl + C para terminar el tunel cuando termines tus pruebas.
echo ======================================================================
echo.
ssh -p 443 -R 0:localhost:8000 -o StrictHostKeyChecking=no a.pinggy.io
pause
