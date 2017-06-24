rem  system disk
d88cut.exe %1 driver.bin 0 0x12 1 0x1000
d88cut.exe %1 data0.bin 0 0x14 1 0x1000
d88cut.exe %1 data1.bin 0 0x15 1 0x0d00
