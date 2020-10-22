md mus
copy *.md mus
copy bonnou.snd mus
cd mus
for %%a in (*.md) do ..\bondec %%a 
..\snd2mml bonnou.snd
del *.org
del *.snd
cd ..
