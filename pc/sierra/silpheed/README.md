# 初期 Sierra dirver

Silpheed用として作成したが、初期のモジュール物は全部同じ

## API

WORKポインタをDS:SIに入れ、No x 2をBPに入れて:0000をfarコール

PATCH LOAD   - API 01
MUTE         - API 02
RESORCE LOAD - API 03
UPDATE       - API 04
VOLUME       - API 05
STOP         - API 07

## WORK DATA

08 - LOAD時にはアドレス配列へのポインタを入れる (API 01/03/04)

