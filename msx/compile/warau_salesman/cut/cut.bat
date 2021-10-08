md mus
cd mus

bcut ..\WARAU_1.DSK DRIVER.BIN 0xb0000 0x1f00
bcut ..\WARAU_1.DSK DATA.BIN 0x10000 0x1a00

rem del DATA*
cd ..
