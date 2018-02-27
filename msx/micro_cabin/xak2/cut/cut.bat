md mus
cd mus
bcut ..\XAK2_O.dsk TONE.BIN 0xDC00 0x200
bcut ..\XAK2_O.dsk BGMDRV.BIN 0x2A00 0xC00
bcut ..\XAK2_G1.dsk SE.BGE 0x3FE00 0x400
bcut ..\XAK2_O.dsk DATA00  0x25800 0x7800

bcut ..\XAK2_G1.dsk DATA10 0x98600 0x3800
bcut ..\XAK2_G2.dsk DATA21 0x3a600 0x5800
bcut ..\XAK2_G2.dsk DATA22 0xa2600 0x4400
bcut ..\XAK2_G3.dsk DATA31 0xa2c00 0x1800
bcut ..\XAK2_G3.dsk DATA32 0x3a600 0x5800
bcut ..\XAK2_G4.dsk DATA41 0x9d400 0x8000
bcut ..\XAK2_G4.dsk DATA42 0x3a600 0x5800
..\fraycut DATA00 D00
..\fraycut DATA10 G10
..\fraycut DATA21 G21
..\fraycut DATA22 G22
..\fraycut DATA31 G31
..\fraycut DATA32 G32
..\fraycut DATA41 G41
..\fraycut DATA42 G42
del DATA*
cd ..
