; 琉球: R.EXE(CRC32:0x45711250)
; hoot 2018/12版以降で動作
;

%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0x40

		ORG	0x0100
		USE16
		CPU	186

start:
		cli
		mov	ax, cs
		mov	ds, ax
		mov	es, ax

		mov	dx, HOOTFUNC
		mov	al, HF_DISABLE		; 初期化中はhoot呼び出しを禁止
		out	dx, al

		mov	ax, cs			; スタック設定
		mov	ss, ax
		mov	sp, stack

		mov	bx, prgend
		add	bx, 0x0f
		shr	bx, 4
		mov	ah, 0x4a		; AH=4a modify alloc memory(ES:BX)
		int	0x21

		mov	ah,0x48			; [DOS] ロードバッファの割り当て
		mov	bx,0x8000		; パラグラフサイズ
		int	0x21
		mov	[ovrparam],ax		; entry更新
		mov	[ovrseg],ax
		mov	[initseg],ax
		mov	[playseg],ax
		mov	[stopseg],ax
		mov	[statseg],ax

		call	drv_load

		mov	ah, 0x25		; hootドライバ登録
		mov	al, int_hoot
		mov	dx, vect_hoot
		int	0x21

		mov	dx, HOOTFUNC
		mov	al, HF_ENABLE		; hoot呼び出しを許可
		out	dx, al
		sti

mainloop:
;		mov	ax, 0x9801		; ダミーポーリング
;		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)〜inp8(HOOTPORT+5)

vect_hoot:
		pusha
		push	ds
		push	es
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	dx, HOOTPORT
		in	al, dx
		cmp	al, HP_PLAY
		jz	short .play
		cmp	al, HP_STOP
		jz	short .fadeout
.ed:
		pop	es
		pop	ds
		popa
		iret
	
.stop:
.fadeout:
		xor	al,al
		mov	[cs:loopflg],al
		call	far [cs:stopofs]
		jmp	short .ed

.play:
		mov	dx,HOOTPORT+3		; Loop flag
		in	al,dx
		mov	[cs:loopflg],al

		mov	dx,HOOTPORT+2		; Song no
		xor	ah,ah
		in	al,dx
		add	ax,ax
		add	ax,mustbl
		mov	bx,ax
		mov	ax,[bx]
		mov	[cs:playofs],ax
		call	far [cs:playofs]	; Load internal data
		jmp	short .ed

; Load EXE
drv_load:
		push	ds
		push	es

		mov dx, vsync_entry
		mov bx, 0x0a*4
		xor ax,ax
		mov es, ax
		mov [es:bx], dx
		mov ax,cs
		mov [es:bx+2], ax

		in	al, 0x02
		and	al, 0xfb
		out	0x02, al
		out 0x64, al

		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	ax, 0x4b03		; [DOS] Overlay Load
		mov	dx, exec_path		; パス名 (DS:DX)
		mov	bx, ovrparam		; パラメータブロック(ES:BX)
		int	0x21

		push	ds
		mov	ax, [cs:ovrseg]
		mov	ds, ax
		mov	al, 0xcb		; Patch: ret -> retf
		mov	[0x82C6], al
		mov	[0x82CD], al
		mov	[0x82F1], al
		mov	[0x82FB], al
		mov	[0x8345], al
		mov	[0x836F], al
		mov	[0x8399], al
		mov	[0x83BF], al
		mov	[0x83FD], al

		mov	ax, [cs:ovrseg]
		mov	ds, ax
		call	far [cs:initofs]	; Sound initialize
		pop	ds

		pop	es
		pop	ds

		ret

vsync_entry:
		cli
		pushf
		pusha
		mov	al, [cs:loopflg]
		cmp	al, 00
		jz	short vse_end

		call	far [cs:statofs]
		test	ax, ax
		jnz	short vse_end

		call	far [cs:stopofs]
		call	far [cs:playofs]
vse_end:
		mov al, 0x20
		out 0x00, al
		out 0x64, al
		popa
		popf
		sti
		iret

exec_path:
	db	'R.EXE',00

ovrofs:
		dw	0x0000
ovrseg:
		dw	0x0000
initofs:
		dw	0x8285
initseg:
		dw	0x0000
playofs:
		dw	0x82F2
playseg:
		dw	0x0000
stopofs:
		dw	0x82C7
stopseg:
		dw	0x0000
statofs:
		dw	0x82D8
statseg:
		dw	0x0000

mustbl:
		dw	0x82F2		; Main BGM
		dw	0x8320		; Game Over
		dw	0x8346		; Name Entry
		dw	0x8370		; Clear
		dw	0x839A		; Title
		dw	0x83C0		; Ending

loopflg:
		db	0x00

; Over ray load用パラメータブロック
ovrparam:
		dw	0			; ロードセグメント
		dw	0			; リロケーションファクタ

		align	0x10
		times 0x100 db 0xff		; スタックエリア
stack:

prgend:
