md mus
cd mus
bcut ..\MADO_1.DSK DRIVER.BIN 0xB0000 0x2000
rem 05EA8
bcut ..\MADO_1.DSK MUSIC10.BIN 0x21EA8 0x2000

rem 02000(2002)
bcut ..\MADO_1.DSK MUSIC11.BIN 0x44002 0x2000
bcut ..\MADO_1.DSK MUSIC12.BIN 0x44EEF 0x2000
bcut ..\MADO_1.DSK MUSIC13.BIN 0x45DED 0x2000

rem 0594B
bcut ..\MADO_1.DSK MUSIC14.BIN 0x4994B 0x2000

rem 06692
bcut ..\MADO_2.DSK MUSIC20.BIN 0x22292 0x2000

rem 02000(2002)
bcut ..\MADO_2.DSK MUSIC21.BIN 0x48002 0x2000
bcut ..\MADO_2.DSK MUSIC22.BIN 0x48D74 0x2000
bcut ..\MADO_2.DSK MUSIC23.BIN 0x49D30 0x2000
bcut ..\MADO_2.DSK MUSIC24.BIN 0x4AB04 0x2000

rem 0559f
bcut ..\MADO_2.DSK MUSIC25.BIN 0x4D59F 0x2000

rem 05c90
bcut ..\MADO_3.DSK MUSIC30.BIN 0x21c90 0x2000

rem 02000(2002)
bcut ..\MADO_3.DSK MUSIC31.BIN 0x44002 0x2000
bcut ..\MADO_3.DSK MUSIC32.BIN 0x44EBD 0x2000
bcut ..\MADO_3.DSK MUSIC33.BIN 0x45EB0 0x2000
bcut ..\MADO_3.DSK MUSIC34.BIN 0x46CC1 0x2000

rem 54bd
bcut ..\MADO_3.DSK MUSIC35.BIN 0xAD4BD 0x2000

rem del DATA*
cd ..
