@echo off
setlocal
pushd "%~dp0"
nasm -f bin -l mm3f_98.lst -o mm3f_98.com mm3_98.asm
set BUILD_RESULT=%ERRORLEVEL%
nasm -f bin -DMIDI=1 -l mm3m_98.lst -o mm3m_98.com mm3_98.asm
popd
exit /b %BUILD_RESULT%
