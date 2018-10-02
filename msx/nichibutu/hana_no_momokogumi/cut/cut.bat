md mus
cd mus

rem $8000
bcut ..\MOMOKO_1.dsk DRIVER.BIN 0xA300 0x0B00
rem $9800
bcut ..\MOMOKO_1.dsk FDAT.BIN 0xE200 0x1b00
bcut ..\MOMOKO_1.dsk PDAT.BIN 0x10000 0x1800
rem $0100
bcut ..\MOMOKO_1.dsk MAIN.BIN 0x2400 0x0D00

cd ..
