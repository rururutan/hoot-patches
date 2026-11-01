@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l p4_98.lst -o p4_98.com p4_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
