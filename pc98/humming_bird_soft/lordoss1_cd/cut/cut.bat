mkdir mus
copy LCD1_MDT.SLD mus\LCD1.MLD
cd mus
..\mdtcut LCD1.MLD
del LCD1.MLD
..\scut 89B9003A 1C1C1B1C 1408 ..\CMAKE.BIN CMAKE00.MLD
..\scut 03B9003A 1C1D1614 1408 ..\CMAKE.BIN CMAKE01.MLD
..\scut 6F647500 E5006D02 2193 ..\CMAKE.BIN CMAKE02.MLD
cd ..