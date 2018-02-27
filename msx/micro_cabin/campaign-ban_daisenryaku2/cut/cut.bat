md mus
cd mus
bcut ..\CWAR2S.DSK DRIVER.BIN 0x3a00 0xc00
bcut ..\CWAR2S.DSK TONE.BIN 0x88200 0x200
bcut ..\/CWAR2S.DSK SE.BGE 0x8da00 0x300
bcut ..\CWAR2S.DSK DATA1 0x88400 0x5600
bcut ..\CWAR2D.DSK DATA2 0x96600 0x2c00
..\fraycut data1 S0
..\fraycut data2 D0
del data1
del data2
cd ..
