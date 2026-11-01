@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l mm4_01.lst -o mm4_01.com mm4_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
