@echo off
set DRIVER=kiss98
setlocal
pushd "%~dp0"
nasm -DKISS=1 -f bin -l%DRIVER%.lst -o %DRIVER%.bin mreq98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
