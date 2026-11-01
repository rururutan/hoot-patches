@echo off
setlocal
pushd "%~dp0"
nasm -f bin -DVERSION21=1 -l mm4_21.lst -o mm4_21.com mm4_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
