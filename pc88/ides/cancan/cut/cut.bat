md mus
cd mus

d88cut ..\%1 DRIVER.BIN 0 0x1 0x1 4096

d88cut ..\%1 MUS00.BIN 0 0x1 0x5 0x800
d88cut ..\%1 MUS01.BIN 0 0x2 0x2 0x800
d88cut ..\%1 MUS02.BIN 0 0x2 0x4 0x800
d88cut ..\%1 MUS03.BIN 0 0x3 0x1 0x800
d88cut ..\%1 MUS04.BIN 0 0x3 0x3 0xc00
d88cut ..\%1 MUS05.BIN 0 0x4 0x1 0xc00
d88cut ..\%1 MUS06.BIN 0 0x4 0x4 0x800
d88cut ..\%1 MUS07.BIN 0 0x5 0x1 0x800

cd ..
