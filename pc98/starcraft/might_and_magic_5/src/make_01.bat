@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l mm5_01.lst -o mm5_01.com mm5_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
