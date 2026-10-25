@echo off
set DRIVER=ub_fm
set OPTION=
call :COMPILE

set DRIVER=ub_md
set OPTION=-DMIDI
call :COMPILE


:COMPILE
setlocal
pushd "%~dp0"
nasm -f bin %OPTION% -l %DRIVER%.lst -o %DRIVER%.com ub_98.asm
set BUILD_RESULT=%ERRORLEVEL%
popd
exit /b %BUILD_RESULT%

