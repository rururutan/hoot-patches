@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l tnt_98.lst -o tnt_98.com tnt_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
