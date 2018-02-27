md mus
cd mus

; 4000
bcut ..\MAISON.dsk DRIVER.BIN 0x006700 0x2f00

; C000
bcut ..\MAISON.dsk DATA.BIN 0x0A800 0x0D00

cd ..
