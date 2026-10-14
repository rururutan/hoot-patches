@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l stratego_98.lst -o STRAT98.COM stratego_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
