@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l mjtk98.lst -o mjtk98.bin mjtk98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
