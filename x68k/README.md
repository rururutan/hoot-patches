# X68000ドライバー

## 仕様書

[MZL氏のところ](https://www.tur-up.net/~ta/x68k/hootknowhow.html)にあります

上記以降に追加された仕様/オプション

IOCTLがある程度実装されています。

| Option name  | Spec |
| ------------ | ---- |
| mfp     | FM割り込みがIRQ6から実機と同様に。Timer-A/Dが有効化) |
| dmaint     | ADCPM終了割り込みの有効化 |
| midiout      | MIDI出力 0:無し 1:MIDI-Board 2:RS-232C |
| midiout_type | MIDI機器 0:NORMAL/1:MT-32 EMU/2:MT-32/3:CM-64/4:SC-55/5:M1 |
| midiout_mix  | Vermouth / MT32Emu時の音量指定 |

