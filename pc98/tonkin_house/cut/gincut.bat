rem MAIN.SEQ/VOIは同名別ファイルなので片方をリネームする
gincut HAK_SEQ.CHN
gincut JYO_SEQ.CHN
gincut SAS_SEQ.CHN
ren MAIN.SEQ MAIN_.SEQ
ren MAIN.VOI MAIN_.VOI
gincut WASI_SEQ.CHN
