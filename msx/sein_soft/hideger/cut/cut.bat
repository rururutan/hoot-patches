md mus
cd mus

; offset B000h
bcut ..\HIDEGER.DSK PSG.BIN 0x28000 0x1000
bcut ..\HIDEGER.DSK OPLL.BIN 0x2a000 0x0c00

cd ..
