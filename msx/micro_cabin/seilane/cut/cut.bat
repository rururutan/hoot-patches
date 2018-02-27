md mus
cd mus
bcut ..\SEILANE1.dsk DRIVER.BIN  0x8CC00 0x1000

bcut ..\SEILANE1.dsk MUS00.BIN  0x8D200 1536
bcut ..\SEILANE2.dsk MUS01.BIN  0x8D200 1280

cd ..
