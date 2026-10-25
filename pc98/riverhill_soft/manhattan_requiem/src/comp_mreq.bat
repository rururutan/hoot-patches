@echo off
set DRIVER=mreq98
setlocal
pushd "%~dp0"
nasm -f bin -l%DRIVER%.lst -o %DRIVER%.bin %DRIVER%.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
