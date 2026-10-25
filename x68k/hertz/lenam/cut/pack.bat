
set OUTTMP=outtmp
set SYSDISK=system
set OPDISK=opening

mkdir %OUTTMP%
mkdir %OUTTMP%\op

for %%a in (%SYSDISK%\*.MUS) do lnmext.exe %%a %OUTTMP%\%%~nxa
for %%a in (%SYSDISK%\*.MCP) do lnmext.exe %%a %OUTTMP%\%%~na.MDT
snd2opm %SYSDISK%\AKI2.SND %OUTTMP%\AKI2.OPM
snd2opm %SYSDISK%\OPING.SND %OUTTMP%\OPING.OPM
for %%a in (%OUTTMP%\*.MUS) do lenamcnv.exe %%a %OUTTMP%\%%~na.OPM
lenamcnv.exe %OUTTMP%\MAZE.MUS %OUTTMP%\MAZE.OPM /B
copy %SYSDISK%\*.PCM %OUTTMP%\
copy %SYSDISK%\OPMDRV.X %OUTTMP%\
copy %SYSDISK%\P.X %OUTTMP%\
copy %SYSDISK%\MID.X %OUTTMP%\
del /Q %OUTTMP%\*.MUS

for %%a in (%OPDISK%\music\*.MUS) do copy %%a %OUTTMP%\op\%%~nxa
for %%a in (%OPDISK%\music\*.MDT) do copy %%a %OUTTMP%\op\%%~nxa
snd2opm %OPDISK%\music\OPING.SND %OUTTMP%\op\OPINGSND.OPM
for %%a in (%OUTTMP%\op\*.MUS) do lenamcnv.exe %%a %OUTTMP%\op\%%~na.OPM /C
copy %OPDISK%\sys\*.PCM %OUTTMP%\op\
copy %OPDISK%\sys\mid.x %OUTTMP%\op\
del /Q %OUTTMP%\op\*.MUS

copy lenam68snd.bin %OUTTMP%\
copy lenam68mid.bin %OUTTMP%\
copy PCMTBL %OUTTMP%\
copy PCMTBL2 %OUTTMP%\op\PCMTBL
