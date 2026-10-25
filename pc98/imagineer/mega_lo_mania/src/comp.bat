@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l mlm98.lst -o mlm98.com mlm98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
