mkdir output
for %%a in (*.MID) do gsenkiext.exe %%a output\%%a
copy GAME.EXE output\
