md mus
cd mus

rem 8000
bcut ..\GRAMC_A.dsk PSGDRV.BIN 0x014000 0x0800
bcut ..\GRAMC_A.dsk FMDRV.BIN 0x015000 0x0800

rem B180
bcut ..\GRAMC_A.dsk MUS00.BIN 0x006000 0x0400
bcut ..\GRAMC_A.dsk MUS01.BIN 0x006400 0x0400
bcut ..\GRAMC_A.dsk MUS02.BIN 0x006800 0x0400
bcut ..\GRAMC_A.dsk MUS03.BIN 0x006C00 0x0400
bcut ..\GRAMC_A.dsk MUS04.BIN 0x007000 0x0600
bcut ..\GRAMC_A.dsk MUS05.BIN 0x007600 0x0400
bcut ..\GRAMC_A.dsk MUS06.BIN 0x007A00 0x0400
bcut ..\GRAMC_A.dsk MUS07.BIN 0x008000 0x0600
bcut ..\GRAMC_A.dsk MUS08.BIN 0x014800 0x0400
bcut ..\GRAMC_A.dsk MUS09.BIN 0x016000 0x0600
bcut ..\GRAMC_A.dsk MUS0A.BIN 0x016600 0x0400
bcut ..\GRAMC_A.dsk MUS0B.BIN 0x016A00 0x0400
bcut ..\GRAMC_A.dsk MUS0C.BIN 0x016E00 0x0400
bcut ..\GRAMC_A.dsk MUS0D.BIN 0x017200 0x0600
bcut ..\GRAMC_A.dsk MUS0E.BIN 0x017800 0x0400
bcut ..\GRAMC_A.dsk MUS0F.BIN 0x017C00 0x0400
bcut ..\GRAMC_B.dsk MUS10.BIN 0x0A8000 0x0600
bcut ..\GRAMC_B.dsk MUS11.BIN 0x0A8600 0x0400
bcut ..\GRAMC_B.dsk MUS12.BIN 0x0A8A00 0x0400
bcut ..\GRAMC_B.dsk MUS13.BIN 0x0A8E00 0x0400
bcut ..\GRAMC_B.dsk MUS14.BIN 0x0A9200 0x0600
bcut ..\GRAMC_B.dsk MUS15.BIN 0x0A9800 0x0400
bcut ..\GRAMC_B.dsk MUS16.BIN 0x0A9C00 0x0400
bcut ..\GRAMC_B.dsk MUS17.BIN 0x0AA000 0x0400
bcut ..\GRAMC_B.dsk MUS18.BIN 0x0AA400 0x0400
bcut ..\GRAMC_B.dsk MUS19.BIN 0x0AA800 0x0400
bcut ..\GRAMC_B.dsk MUS1a.BIN 0x0AAC00 0x0400
bcut ..\GRAMC_B.dsk MUS1b.BIN 0x0AB000 0x0600
bcut ..\GRAMC_B.dsk MUS1c.BIN 0x0AB600 0x0400
bcut ..\GRAMC_B.dsk MUS1d.BIN 0x0ABA00 0x0600
bcut ..\GRAMC_B.dsk MUS1e.BIN 0x0AC000 0x0600
bcut ..\GRAMC_B.dsk MUS1f.BIN 0x0AC600 0x0400
bcut ..\GRAMC_B.dsk MUS20.BIN 0x0ACA00 0x0400
bcut ..\GRAMC_B.dsk MUS21.BIN 0x0ACE00 0x0400
bcut ..\GRAMC_B.dsk MUS22.BIN 0x0AD200 0x0600
bcut ..\GRAMC_B.dsk MUS23.BIN 0x0AD800 0x0400
bcut ..\GRAMC_B.dsk MUS24.BIN 0x0ADC00 0x0400

cd ..