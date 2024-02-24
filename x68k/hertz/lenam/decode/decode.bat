md mus
copy *.mus mus
copy *.mcp mus
cd mus
for %%a in (*.mus) do ..\lnmext %%a
for %%a in (*.mcp) do ..\lnmext %%a
cd ..
