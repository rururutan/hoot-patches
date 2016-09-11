md mus
cd mus

d88cut ..\can1.d88 DRIVER.BIN 0 109 0x8 0x1800 0x170
d88cut ..\can1.d88 DRIVER2.BIN 0 114 0x3 0x00d0 0x330

d88cut ..\can1.d88 MUS00.BIN 0 2 0x5 0x0800
d88cut ..\can1.d88 MUS01.BIN 0 2 0x7 0x0800
d88cut ..\can1.d88 MUS02.BIN 0 3 0x1 0x0800
d88cut ..\can1.d88 MUS03.BIN 0 3 0x3 0x0800
d88cut ..\can1.d88 MUS04.BIN 0 3 0x5 0x0c00
d88cut ..\can1.d88 MUS05.BIN 0 3 0x8 0x0c00
d88cut ..\can1.d88 MUS06.BIN 0 4 0x3 0x0800
d88cut ..\can1.d88 MUS07.BIN 0 4 0x5 0x0c00

cd ..
