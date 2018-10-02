md mus
cd mus

rem $8000
bcut ..\MJS_A.dsk DRIVER.BIN 0x2F700 0x0B00
rem $9800
bcut ..\MJS_A.dsk FDAT.BIN 0x24600 0x1A00
bcut ..\MJS_A.dsk PDAT.BIN 0x26000 0x1A00
rem $0100
bcut ..\MJS_A.dsk MAIN.BIN 0x27800 0x0D00

cd ..
