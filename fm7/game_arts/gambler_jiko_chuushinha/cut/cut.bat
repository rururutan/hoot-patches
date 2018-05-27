mkdir mus
cd mus

..\txdfile.exe ..\THEXER.D77
rem 1CFB
d88cut ..\THEXER.D77 INIT.BIN 0 0x00 4 0x0400
d88cut ..\THEXER.D77 END2.BIN 0 0x35 1 0x0400

cd ..
