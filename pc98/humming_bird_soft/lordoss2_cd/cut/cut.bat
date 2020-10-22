mkdir mus
copy *.MLD mus
cd mus
attrib -R *.MLD
for %%a in (*.MLD) do ..\lor2ext.exe %%a
..\lor2cext ..\MUSIC.DAT
cd ..
