@echo off 

rem EMERALD DRAGON MUSIC DISK (PC98) ドライバ切り出し用BATファイル
 
if "%1"=="" goto usage
d88cut %1 MAIN 0 1 1 0x3000
goto fin

:usage
echo EMERALD DRAGON(PC98)ドライバ切り出し用バッチファイル
echo ed98cut [Visual Disk D88 image]
echo ※曲データは vdcuth [D88 image]として切り出してください。

:fin
