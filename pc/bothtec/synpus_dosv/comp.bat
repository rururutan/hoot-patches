@echo off
set DRIVER=synp_at
nasm -f bin -l %DRIVER%.lst -o %DRIVER%.com %DRIVER%.asm
