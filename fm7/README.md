# FM-7/77AV汎用ドライバ仕様

## 独自機能

| Port  | R/W | Spec |
| ----- | --- | ---- |
| FD58h | R   | リクエスト(00:none 02:stop 01:play) |
| FD59h | R   | リクエストコード(00~07bit) |
| FD59h | W   | 指定コードのファイルをロード |
| FD5Ah | R   | リクエストコード(08~15bit) |
| FD5Bh | R   | リクエストコード(16~23bit) |
| FD5Ch | R   | リクエストコード(24~31bit) |

## ビルド

[as68]()と[s19tobin](https://github.com/rururutan/s19tobin)を使用しています。
