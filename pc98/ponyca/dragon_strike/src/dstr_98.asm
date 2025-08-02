; Advance D&D Dragon Strike SOUND.EXE
; (C) RuRuRu
; 2013/10/20 1st Release
; 2025/08/01 Fix tempo
;
%include 'hoot.inc'
int_hoot	equ	0x7f
int_driver	equ	0x7e

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

		mov	bx,0x1000		; 大きさ適当
		mov	ah,0x48			; AH=48 メモリ割り当て(SOUND.EXE用)
		int	0x21
		mov	[ovrparam],ax		; entry更新
		mov	[drvseg], ax
		mov	[drvseg2], ax
		mov	[drvseg3], ax
		mov	[drvseg4], ax
		mov	[drvseg5], ax
		mov	[drvseg6], ax

		call	drv_load

		mov	ah, 0x25
		mov	al, 0x0a
		mov	dx, vsync_ent
		int	0x21

		in	al, 0x02
		and	al, 0xfb
		out	0x02, al
		out	0x64, al

		mov	ah, 0x25		; hootドライバ登録
		mov	al, int_hoot
		mov	dx, vect_hoot
		int	0x21

		mov	dx, HOOTFUNC
		mov	al, HF_ENABLE		; hoot呼び出しを許可
		out	dx, al
		sti

mainloop:
		mov	ax, 0x9801		; ダミーポーリング
		int	0x18
		jmp	short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)

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
		call	far [cs:stopent]
		jmp	short .ed

.play:
		call	far [cs:stopent]
		cli
		call	drv_load
		sti

		mov	cx, 0x4
.wait
		call	waitvsync
		loop	.wait

		push	ds
		mov	ax, [drvseg]
		mov	ds, ax
		call	far [cs:loadent]
		pop	ds

		call	far [playent]

		jmp	.ed

waitvsync:
		push	ax
		push	dx
		mov	dx,0xa0

.waitvsync_1:
		in	al,dx
		test	al,0x20
		jnz	.waitvsync_1

.waitvsync_2:
		in	al,dx
		test	al,0x20
		jz	.waitvsync_2
		pop	dx
		pop	ax
		ret

; SOUND.EXEからコールされるファイルロード関数
; BX:BP = buf
; CX = size
file_load:
		push	ds
		push	dx
		push	bx
		push	ax

		mov	ds,bx
		mov	dx,bp
		xor	bx,bx
		mov	ah,0x3f			; [DOS] read hundle
		int	0x21

		pop	ax
		pop	bx
		pop	dx
		pop	ds
		retf

; SOUND.EXEロード
drv_load:
		mov	ax, 0x4b03		; [DOS] Overlay Load
		mov	dx, exec_path		; パス名 (DS:DX)
		mov	bx, ovrparam		; パラメータブロック(ES:BX)
		int	0x21

		push	ds
		mov	ax, [drvseg]
		mov	ds, ax
		call	far [cs:initent]
		mov	ax, file_load
		mov	[ds:0x110], ax
		mov	[ds:0x112], cs
		pop	ds

		ret

vsync_ent:
		out	0x64, al
		push	ax
		mov	al, 0x20
		out	0x00, al
		pop	ax
		call	far [cs:irqent]
		mov	al, [irq_cnt]
		inc	al
		mov	[irq_cnt],al
		cmp	al,2
		jz	ent_end
		mov	al, 0
		mov	[irq_cnt],al
		call	far [cs:irqent]
ent_end:
		iret

irq_cnt:
	db	00

exec_path:
	db	'SOUND.EXE',00

initent;
	dw	0x0000
;	dw	0x187
drvseg:
	dw	0
playent;
	dw	0x281
drvseg2:
	dw	0
loadent:
	dw	0x1e8
drvseg3:
	dw	0
fadeent:
	dw	0x215
drvseg4:
	dw	0
stopent:
	dw	0x22b
drvseg5:
	dw	0
irqent:
	dw	0x35e
drvseg6:
	dw	0


; オーバレイロード用パラメータブロック
ovrparam:
		dw	0			; SOUND.EXE用ロードセグメント
		dw	0			; リロケーションファクタ

		align	0x10
		times 0x100 db 0xff		; スタックエリア

stack:
prgend:
		ends
