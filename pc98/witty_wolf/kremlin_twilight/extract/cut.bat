extract_ktw.exe MY.CMB output
extract_ktw.exe PESNIF.CMB output
extract_ktw.exe PESNIM.CMB output
copy output\MY\*.m* output\
copy output\PESNIF\*.m* output\
copy output\PESNIM\*.m* output\
copy fmp3.com output\
rmdir /Q /S output\MY
rmdir /Q /S output\PESNIF
rmdir /Q /S output\PESNIM
