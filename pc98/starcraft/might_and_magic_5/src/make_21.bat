@echo off
setlocal
pushd "%~dp0"
nasm -f bin -DVERSION21=1 -l mm5_21.lst -o mm5_21.com mm5_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
