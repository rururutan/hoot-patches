md mus
cd mus
bcut ..\GOLV2_O.DSK DRIVER.BIN 0x000c00 0x4000
bcut ..\GOLV2_G.DSK DRIVER2.BIN 0x0a8000 0x3f00
bcut ..\GOLV2_G.DSK DRIVER3.BIN 0x0abe00 0x3a00

rem del DATA*
cd ..
