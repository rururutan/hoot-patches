md mus
cd mus

rem 7000
bcut ..\ASUCCESS.DSK MUS0.BIN 0x60C00 0x0300
bcut ..\ASUCCESS.DSK MUS1.BIN 0x61000 0x0300

rem 74C0
bcut ..\ASUCCESS.DSK DRIVER.BIN 0x61400 0x0800

rem 8000
bcut ..\ASUCCESS.DSK DRIVER2.BIN 0x79800 0x1400

rem del DATA*
cd ..
