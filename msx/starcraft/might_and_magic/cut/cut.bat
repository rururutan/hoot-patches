md mus
cd mus

rem CB7F
bcut ..\MM1.dsk DRIVER.BIN 0x01c00 0x1000
rem D1A0
bcut ..\MM1.dsk DATA1.BIN 0x04d000 0x0200
bcut ..\MM1.dsk DATA2.BIN 0x04d200 0x0200
bcut ..\MM1.dsk DATA3.BIN 0x04d400 0x0200
bcut ..\MM1.dsk DATA4.BIN 0x04d600 0x0200
bcut ..\MM1.dsk DATA5.BIN 0x04d800 0x0200
bcut ..\MM1.dsk DATA6.BIN 0x04da00 0x0200
bcut ..\MM1.dsk DATA7.BIN 0x04dc00 0x0200
bcut ..\MM1.dsk DATA8.BIN 0x04de00 0x0200
bcut ..\MM1.dsk DATA9.BIN 0x04e000 0x0200
bcut ..\MM1.dsk DATAa.BIN 0x04e200 0x0200


cd ..
