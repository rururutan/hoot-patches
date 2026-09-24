@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l ultse_98.lst -o ultse_98.com ultse_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
