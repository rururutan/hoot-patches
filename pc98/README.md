# PC-98x1ドライバー

## 仕様書

[ゆいさん](http://retropc.net/yui/hoot/PC98.TXT)のWebにあります

上記以降に追加されたオプション

| Option name  | Spec |
| ------------ | ---- |
| clockmul     | クロック倍率 (cpuclock x clockmulが実際の動作クロック |
| showfm3ex    | FM3chをOP単位で表示 主に効果音モードを使用しているタイトル用 |
| midiout      | MIDI出力 0:無し 1:MPU98 2:RS-232C |
| midiout_type | MIDI機器 0:NORMAL/1:MT-32 EMU/2:MT-32/3:CM-64/4:SC-55/5:M1 |
| midiout_mix  | Vermouth / MT32Emu時の音量指定 |


## ビルド

### .asm
 [NASM](https://www.nasm.us/)を使用します。

### .a86
 [LSI C-86 試食版](https://www.vector.co.jp/soft/maker/lsi/se001169.html)を使用します。16bitプログラムなのでx86環境以外は実行に[MS-DOS Player](http://takeda-toshiya.my.coocan.jp/msdos/)が必要です。


