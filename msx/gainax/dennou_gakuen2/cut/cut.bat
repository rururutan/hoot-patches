set DISK_A=den2_a.dsk
set DISK_C=den2_c.dsk

md MUS
bcut %DISK_A% MUS\DRIVER 0x01400 0x400
md tmp
cd tmp
..\den2cut ..\%DISK_A%
copy *.MUS ..\MUS
del /Q *.*
..\den2cut ..\%DISK_C%
copy *.MUS ..\MUS
del /Q *.*
cd ..
rmdir tmp
