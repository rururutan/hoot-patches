md mus
cd mus
bcut ..\ILLCITY1.DSK DRIVER.BIN 0x02C00 0xc00
bcut ..\ILLCITY1.DSK TONE.BIN 0x03800 0x200
bcut ..\ILLCITY1.DSK SE.BGE 0x03a00 0x800
bcut ..\ILLCITY1.DSK BGM10.BIN 0x025800 0x3c00
bcut ..\ILLCITY2.DSK BGM20.BIN 0x099400 0xC400

bcut ..\ILLCITY1.DSK G1007.BGM 0x04268 0x400
bcut ..\ILLCITY1.DSK G1008.BGM 0x04589 0x200
bcut ..\ILLCITY1.DSK G1009.BGM 0x04614 0x200
bcut ..\ILLCITY1.DSK G100A.BGM 0x046b4 0x200
bcut ..\ILLCITY1.DSK G100B.BGM 0x04801 0x200
bcut ..\ILLCITY1.DSK G100C.BGM 0x0491A 0x200


bcut ..\ILLCITY7.DSK BGM70.BIN 0x070600 0xb200
bcut ..\ILLCITY7.DSK BGM71.BIN 0x08a800 0x10800
bcut ..\ILLCITY7.DSK BGM72.BIN 0x0a6c00 0x1e00

rem bcut ..\ILLCITY1.DSK BGM23.BIN 0x04AE00 0x3B000
rem bcut ..\ILLCITY2.DSK BGM3.BIN 0x038000 0x17000

..\fraycut BGM10.BIN G10
..\fraycut BGM20.BIN G20
..\fraycut BGM70.BIN G70
..\fraycut BGM71.BIN G71
..\fraycut BGM72.BIN G72

del BGM*.BIN
cd ..