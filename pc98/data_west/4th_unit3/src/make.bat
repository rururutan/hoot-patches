@echo off
nasm -f bin -o tfu3_98.com tfu3_98.asm
if errorlevel 1 exit /b 1
