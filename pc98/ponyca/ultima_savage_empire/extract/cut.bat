extract_se.exe MUSIC.LZC output
extract_se.exe MUSICDRV.LZC output
copy output\MUSICDRV.LZC\000.bin output\FMDRV.BIN
copy output\MUSIC.LZC\*.bin output\
rmdir /Q /S output\MUSIC.LZC
rmdir /Q /S output\MUSICDRV.LZC

