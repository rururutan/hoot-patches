# MSX汎用ドライバ仕様

## 独自IOポート

* Port 02 リクエスト(00:none 01:stop 02:play)
* Port 03 リクエストコード(00~07bit)
* Port 04 リクエストコード(08~15bit)
* Port 05 リクエストコード(16~23bit)
* Port 06 リクエストコード(24~31bit)
* Port 07 サポート音源(0bit:YM2413 1bit:MSX-Audio 2bit:YMF271B)


## ビルド

[XASM](https://github.com/rururutan/xasm-w64)を使用しています。

