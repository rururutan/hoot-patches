as68 patch.s -o patch.s19 -l patch.lst
s19tobin patch.s19 patch.bin
del patch2
ren patch.bin patch
