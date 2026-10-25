@echo off
set DRIVER=gsenki98
setlocal
pushd "%~dp0"

nasm -f bin -DMODE=0 -lgsenkf98.lst -o gsenkf98.com %DRIVER%.asm
set BUILD_RESULT=%ERRORLEVEL%
popd

nasm -f bin -DMODE=1 -lgsenkm98.lst -o gsenkm98.com %DRIVER%.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
