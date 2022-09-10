@echo off
set DRIVER=br3_98
msdos r86 %DRIVER%.a86
msdos lld -Fc -o %DRIVER%.com %DRIVER%.obj
