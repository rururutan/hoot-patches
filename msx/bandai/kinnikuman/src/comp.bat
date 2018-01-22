xasm /b400 patch.z80
del patch
del patch.lst
ren patch.bin patch
if errorlevel 1 pause
