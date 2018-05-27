as68 patch.s -o patch.s19 -l patch.lst
del patch.bin
msdos mot2bin.exe patch.s19
