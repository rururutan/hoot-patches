md mus
cd mus

rem CB7F
bcut ..\MM2_1.dsk DRIVER.BIN 0x0777f 0x1000
rem D1A0
bcut ..\MM2_1.dsk DATA1.BIN 0x0aa400 0x0400
bcut ..\MM2_1.dsk DATA2.BIN 0x0aa800 0x0400
bcut ..\MM2_1.dsk DATA3.BIN 0x0aac00 0x0400
bcut ..\MM2_1.dsk DATA4.BIN 0x0ab000 0x0400
bcut ..\MM2_1.dsk DATA5.BIN 0x0ab400 0x0200
bcut ..\MM2_1.dsk DATA6.BIN 0x0ab600 0x0400
bcut ..\MM2_1.dsk DATA7.BIN 0x0aba00 0x0200
bcut ..\MM2_1.dsk DATA8.BIN 0x0abc00 0x0200
bcut ..\MM2_1.dsk DATA9.BIN 0x0abe00 0x0200


cd ..
