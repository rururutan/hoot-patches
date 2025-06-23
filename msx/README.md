# MSX汎用ドライバ仕様

デフォルトの音量バランスはSONY HB-F1XDJ基準

## 独自IOポート

* Port 02 R/リクエスト(00:none 01:stop 02:play)
* Port 03 R/リクエストコード(00~07bit) W/ファイル1ロード
* Port 04 R/リクエストコード(08~15bit) W/ファイル2ロード
* Port 05 R/リクエストコード(16~23bit)
* Port 06 R/リクエストコード(24~31bit)
* Port 07 R/サポート音源(0bit:YM2413 1bit:MSX-Audio 2bit:YMF271B)


## ビルド

[XASM](https://github.com/rururutan/xasm-w64)を使用しています。

