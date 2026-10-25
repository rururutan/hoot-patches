mkdir output
for %%a in (*.MUS) do khlext %%a output\%%a
khlext SOUND.DAT output\SOUND.DAT
cp TUIOKU.EXE output\