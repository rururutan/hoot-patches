@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l kuro_98.lst -o kuro_98.com kuro_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
