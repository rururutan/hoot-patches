md mus
cd mus

bcut ..\COLUMNS.dsk DRIVER.BIN 0xB0000 0x3e00
bcut ..\COLUMNS.dsk DECODE.BIN 0x010000 0x04d
bcut ..\COLUMNS.dsk MAIN.BIN 0x014000 0x04000

cd ..
