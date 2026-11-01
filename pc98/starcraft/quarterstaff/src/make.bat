@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l qs_98.lst -o qs_98.com qs_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
