extract_ktw.exe SONGM.CMB output
extract_ktw.exe SONGS.CMB output
copy output\SONGM\*.m* output\
copy output\SONGS\*.m* output\
copy fmp3.com output\
rmdir /Q /S output\SONGM
rmdir /Q /S output\SONGS
