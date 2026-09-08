@echo off
set DRIVER=STRAWB98
nasm -f bin -l %DRIVER%.lst -o %DRIVER%.com %DRIVER%.asm
