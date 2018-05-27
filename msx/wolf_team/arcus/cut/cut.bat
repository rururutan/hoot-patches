md mus
cd mus
bcut ..\ARCUS_1.DSK PSGDRV.BIN 0x45000 0x1400
bcut ..\ARCUS_1.DSK OPLLDRV.BIN 0x46800 0x1800
rem bcut ..\ARCUS_1.DSK TONE.BIN 0x44C00 0x0400

bcut ..\ARCUS_1.DSK MUS000.BIN 0x2B00 0x0D5
bcut ..\ARCUS_1.DSK MUS001.BIN 0x3A80 0x13E

..\arcusmcut.exe ..\ARCUS_1.DSK MUS1
..\arcusmcut.exe ..\ARCUS_2.DSK MUS2
..\arcusmcut.exe ..\ARCUS_3.DSK MUS3
cd ..
