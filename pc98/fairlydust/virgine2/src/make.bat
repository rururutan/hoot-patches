@echo off
setlocal
pushd "%~dp0"
nasmfmt vgn2_98.com
nasm -f bin -l vgn2_98.lst -o vgn2_98.com vgn2_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
