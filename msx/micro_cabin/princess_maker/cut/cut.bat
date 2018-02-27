md mus
cd mus

bcut ..\PM_1.dsk BGMDRV.BIN 0x3000 0xC00
bcut ..\PM_1.dsk SE.BGE 0xB1000 0x200
bcut ..\PM_1.dsk TONE.BIN 0xB1200 0x200
bcut ..\PM_1.dsk DATA01 0xF400 0x3400
rem DISK 2~5はCRCが同じものがDISK1,6に存在
rem bcut ..\PM_2.dsk DATA02 0x1A000 0x8200
rem bcut ..\PM_3.dsk DATA03 0x1A000 0x8200
rem bcut ..\PM_4.dsk DATA04 0x1A000 0x8200
rem bcut ..\PM_5.dsk DATA05 0x1CC00 0x8200
bcut ..\PM_6.dsk DATA06 0x6400 0x9E00
bcut ..\PM_7.dsk DATA07 0x2800 0x1C00

..\fraycut DATA01 G1
..\fraycut DATA06 G6
..\fraycut DATA07 G7
del DATA*
cd ..
