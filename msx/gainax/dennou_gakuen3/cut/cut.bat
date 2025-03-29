set DISK_A=den3_a.dsk
set DISK_C=den3_c.dsk

md MUS
bcut %DISK_A% MUS\DRIVER 0x01600 0x0e00
md tmp
cd tmp
..\den2cut ..\%DISK_A%
copy *.DAT ..\MUS
del /Q *.*
..\den2cut ..\%DISK_C%
copy TOPOVR.DAT ..\MUS
copy TOPEND.DAT ..\MUS
copy SAMBA.DAT ..\MUS
copy TOPFLY.DAT ..\MUS\TOPFLY_.DAT
del /Q *.*
cd ..
rmdir tmp
