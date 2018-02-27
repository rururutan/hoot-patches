md mus
cd mus
bcut ..\XAK_D.dsk DATA0  0x15c00 0x1a00
bcut ..\XAK_G1.dsk TONE.BIN 0x82600 0x200
bcut ..\XAK_G1.dsk DATA1 0x81e00 0xd000
bcut ..\XAK_G2.dsk DATA2 0x83600 0x15600
..\fraycut DATA0 D0
..\fraycut DATA1 G1
..\fraycut DATA2 G2
del DATA*
cd ..
