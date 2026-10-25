md mus
cd mus

rem 1600
bcut ..\DS#13_1.DSK DRIVER.BIN 0xb1500 0x2100
rem data 48F5
bcut ..\DS#13_1.DSK DATA.BIN 0x44000 0x8000

cd ..
