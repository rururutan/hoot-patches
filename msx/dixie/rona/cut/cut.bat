md mus
cd mus
bcut ..\rona_a.dsk IPL.BIN 0x0000 0x200

rem 8a00
bcut ..\rona_a.dsk SEDRV.BIN 0x06ca00 0x1200

rem d000
bcut ..\rona_a.dsk MUSDRV.BIN 0x07800 0x1000

bcut ..\rona_a.dsk FM00.BIN 0x0a5600 0x400
bcut ..\rona_a.dsk FM01.BIN 0x0a5a00 0x400
bcut ..\rona_a.dsk FM02.BIN 0x0a5e00 0x400
bcut ..\rona_a.dsk FM03.BIN 0x0a6200 0x400
bcut ..\rona_a.dsk FM04.BIN 0x0a6600 0x1000
bcut ..\rona_a.dsk FM05.BIN 0x0a7600 0x800
bcut ..\rona_a.dsk FM06.BIN 0x0a7e00 0x400
bcut ..\rona_a.dsk FM07.BIN 0x0a8200 0x900
bcut ..\rona_a.dsk FM08.BIN 0x0a8c00 0x400
bcut ..\rona_a.dsk FM09.BIN 0x0a9000 0xa00
bcut ..\rona_a.dsk FM10.BIN 0x0a9a00 0xc00
bcut ..\rona_a.dsk FM11.BIN 0x0aa600 0x600
bcut ..\rona_a.dsk FM12.BIN 0x0aac00 0x200
bcut ..\rona_a.dsk FM13.BIN 0x0aae00 0x800
bcut ..\rona_a.dsk FM14.BIN 0x0ab600 0x400
bcut ..\rona_a.dsk FM15.BIN 0x0aba00 0x600
bcut ..\rona_a.dsk FM16.BIN 0x0ac000 0x400
bcut ..\rona_a.dsk FM17.BIN 0x0ac400 0xa00
bcut ..\rona_a.dsk FM18.BIN 0x0ace00 0x400
bcut ..\rona_a.dsk FM19.BIN 0x0ad200 0x400
bcut ..\rona_a.dsk FM20.BIN 0x0ad600 0x400
bcut ..\rona_a.dsk FM21.BIN 0x0ada00 0x200
bcut ..\rona_a.dsk FM22.BIN 0x0adc00 0x200

bcut ..\rona_a.dsk PSG00.BIN 0x0ade00 0x200
bcut ..\rona_a.dsk PSG01.BIN 0x0ae000 0x200
bcut ..\rona_a.dsk PSG02.BIN 0x0ae200 0x200
bcut ..\rona_a.dsk PSG03.BIN 0x0ae400 0x200
bcut ..\rona_a.dsk PSG04.BIN 0x0ae600 0xa00
bcut ..\rona_a.dsk PSG05.BIN 0x0af000 0x400
bcut ..\rona_a.dsk PSG06.BIN 0x0af400 0x200
bcut ..\rona_a.dsk PSG07.BIN 0x0af600 0x400
bcut ..\rona_a.dsk PSG08.BIN 0x0afa00 0x200
bcut ..\rona_a.dsk PSG09.BIN 0x0afc00 0x600
bcut ..\rona_a.dsk PSG10.BIN 0x0b0200 0x600
bcut ..\rona_a.dsk PSG11.BIN 0x0b0800 0x400
bcut ..\rona_a.dsk PSG12.BIN 0x0b0c00 0x200
bcut ..\rona_a.dsk PSG13.BIN 0x0b0e00 0x400
bcut ..\rona_a.dsk PSG14.BIN 0x0b1200 0x200
bcut ..\rona_a.dsk PSG15.BIN 0x0b1400 0x200
bcut ..\rona_a.dsk PSG16.BIN 0x0b1600 0x200
bcut ..\rona_a.dsk PSG17.BIN 0x0b1800 0x400
bcut ..\rona_a.dsk PSG18.BIN 0x0b1c00 0x200
bcut ..\rona_a.dsk PSG19.BIN 0x0b1e00 0x200
bcut ..\rona_a.dsk PSG20.BIN 0x0b2000 0x200

bcut ..\rona_a.dsk FM23.BIN 0x0b2200 0x200
bcut ..\rona_a.dsk PSG21.BIN 0x0b2400 0x200
bcut ..\rona_a.dsk PSG22.BIN 0x0b2600 0x200
bcut ..\rona_a.dsk PSG23.BIN 0x0b2800 0x200
bcut ..\rona_a.dsk PSG24.BIN 0x0b2a00 0x400

cd ..
