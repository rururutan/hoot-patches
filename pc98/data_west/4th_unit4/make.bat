@echo off
nasm -f bin -o tfu4_98.com tfu4_98.asm
if errorlevel 1 exit /b 1
