md mus
cd mus

rem 3164
bcut ..\mule.dsk DRIVER.BIN 0x057064 0x3000
bcut ..\mule.dsk DATA.BIN 0x051000 0x0b80
rem 85ca
bcut ..\mule.dsk DRIVER2.BIN 0x075ca 0x03000
rem bb9f
bcut ..\mule.dsk DATA2.BIN 0x0ab9f 0x0161

cd ..
