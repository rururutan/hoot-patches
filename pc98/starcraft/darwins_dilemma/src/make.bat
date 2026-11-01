@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l dd_98.lst -o dd_98.com dd_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
