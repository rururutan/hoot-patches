; Emerald Dragon Music Disk	(C)Basho House/Glodia

%include 'hoot.inc'

		ORG	0x0000
		USE16
		CPU	186

DRIVERSEG	equ	0x1000			; サウンドドライバ配置セグメント

start:		cli
		cld
		mov	dx,HOOTFUNC
		mov	al,HF_DISABLE		; 初期化中はhoot呼び出しを禁止
		out	dx,al

		xor	ax,ax			; 超適当にスタックエリアを確保
		mov	ss,ax
		mov	sp,0x1000
		mov	ds,ax
		mov	es,ax
		mov	word [0x7f*4],hf_entry	; INT 7F hootドライバ登録
		mov	[0x7f*4+2],cs

		mov	ax,DRIVERSEG
		mov	ds,ax
		mov	es,ax
		call	0x1E25	; 音源判定
		MOV	Byte [0x0E8],01		; FM enable
		call	0x0FB0			; Music init

		mov	dx,HOOTFUNC		; hoot呼び出しを許可
		mov	al,HF_ENABLE
		out	dx,al
		sti

mainloop:
		mov	ax,0x9801
		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98VX::Play  ロード前
; inp8(HOOTPORT) = 1 → PC98VX::Play  ロード後
; inp8(HOOTPORT) = 2 → PC98VX::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)

hf_entry:	push	ds
		push	es
		pusha
		mov	ax,cs
		mov	ds,ax
		mov	es,ax
		mov	dx,HOOTPORT
		in	al,dx
		cmp	al,HP_PLAY
		jz	short .stop
		cmp	al,HP_LOADPLAY
		jz	short .play
		cmp	al,HP_STOP
		jz	short .fadeout
.ed:		popa
		pop	es
		pop	ds
		iret

.stop:
		call	0x0E36			; Music disable
		jmp	short .ed

.play:
		call	0x0DFC			; Music enable

		xor	ax,ax
		mov	dx,HOOTPORT+4		; パラメータ読み取り (bit7:ループフラグ)
		in	al,dx			; Loop flag
		mov	di, 0x20AD
		call	0x1093			; Music play
		jmp	short .ed

.fadeout:
		call	0x011F2	; 演奏停止
		jmp	short .ed

