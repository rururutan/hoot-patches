@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l lenam_98.lst -o LENAM98.COM lenam_98.asm
if errorlevel 1 goto fail
nasm -DMIDI -f bin -l lenam_98m.lst -o LENAM98M.COM lenam_98.asm
if errorlevel 1 goto fail
popd
exit /b 0
:fail
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%
