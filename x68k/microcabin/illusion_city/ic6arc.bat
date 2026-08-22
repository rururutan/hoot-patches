set X68Tool=C:\x68\
set A_DISK=%CD%\A\
set B_DISK=%CD%\B\
set D_DISK=%CD%\D\
set E_DISK=%CD%\E\
set G_DISK=%CD%\G\
set Tool=%CD%

mkdir temp
cd temp
mkdir GROUPMD
mkdir GROUP00
mkdir IMUS
copy ..\%A_DISK%\IMUS\* IMUS\
copy ..\%A_DISK%\GROUPMD\* GROUPMD\
copy ..\%A_DISK%\SE_TONE.ZMD .
copy ..\%A_DISK%\ZMUSIC.X .\ZM.X
run68 %X68Tool%\lzx.x -d -oZMUSIC.X ZM.X
del ZM.X
copy ..\%A_DISK%\IC98.BEM .
copy ..\%A_DISK%\IC98.BGE .
copy ..\%A_DISK%\ICITY.ZPD .
copy ..\%B_DISK%\GROUP00\000018.DAT GROUP00\
copy ..\%B_DISK%\GROUP00\000019.DAT GROUP00\
copy ..\%B_DISK%\GROUP00\00002?.DAT GROUP00\
copy ..\%B_DISK%\GROUP00\00003?.DAT GROUP00\
copy ..\%B_DISK%\GROUP00\00004?.DAT GROUP00\
del GROUP00\000048.DAT
del GROUP00\000049.DAT
copy ..\%D_DISK%\GROUP00\000021.DAT GROUP00\
copy ..\%E_DISK%\GROUP00\000043.DAT GROUP00\
copy ..\%E_DISK%\GROUP00\000061.DAT GROUP00\
copy ..\%E_DISK%\GROUP00\000062.DAT GROUP00\
copy ..\%G_DISK%\GROUP00\000025.DAT GROUP00\
cd GROUPMD
for %%a in (*.DAT) do %Tool%\ic68decompress.exe "%%a" "%%~na.ZMD"
del *.DAT
cd ..
cd GROUP00
for %%a in (*.DAT) do %Tool%\ic68decompress.exe "%%a" "%%~na.ZMD"
del *.DAT
cd ..
%Tool%\ic98cut.exe IC98.BEM
%Tool%\ic98cut.exe IC98.BGE
del IC98.BEM
del IC98.BGE
