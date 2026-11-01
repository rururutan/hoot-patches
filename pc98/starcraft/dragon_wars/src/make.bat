@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l dw_98.lst -o dw_98.com dw_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
