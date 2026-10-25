@echo off
set DRIVER=arctc_98
setlocal
pushd "%~dp0"
nasm -f bin -l%DRIVER%.lst -o %DRIVER%.com %DRIVER%.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
