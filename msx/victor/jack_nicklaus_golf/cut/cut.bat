md mus
cd mus

rem 5000
bcut ..\JNGOLF1.DSK PMUS1.BIN 0x5a00 0x00200
bcut ..\JNGOLF1.DSK FMUS1.BIN 0x5c00 0x00200
bcut ..\JNGOLF1.DSK PMUS2.BIN 0x5e00 0x00400
bcut ..\JNGOLF1.DSK FMUS2.BIN 0x6200 0x00800

rem bcut ..\JNGOLF2.DSK PMUS3.BIN 0x74d8 0x00056
bcut ..\JNGOLF2.DSK PMUS3.BIN 0x74d8 0x00057
bcut ..\JNGOLF2.DSK FMUS3.BIN 0x752e 0x00071
bcut ..\JNGOLF2.DSK PMUS4.BIN 0x759f 0x0030f
bcut ..\JNGOLF2.DSK FMUS4.BIN 0x78ae 0x0047b
bcut ..\JNGOLF2.DSK PMUS5.BIN 0x7d29 0x0021b
bcut ..\JNGOLF2.DSK FMUS5.BIN 0x7f44 0x0039f

rem 6600
bcut ..\JNGOLF1.DSK PSGDRV.BIN 0x4800 0x00800
bcut ..\JNGOLF1.DSK OPLLDRV.BIN 0x5000 0x00800

cd ..
