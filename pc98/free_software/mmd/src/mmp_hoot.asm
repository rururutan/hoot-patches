; MIDI Music Driver M.M.D.
; メインルーチン (for NASM)

%include 'hoot.inc'

		ORG		0x0100
		USE16
		CPU		186

start:
		cli
		mov		ax,cs
		mov		ds,ax
		mov		es,ax
		mov		ax,cs
		mov		ds,ax

		mov		ax,0x257f	; hootドライバ登録
		mov		dx,vect_7f
		int		0x21

		sti
mainloop:
		mov		ax,0x9801		; ダミーポーリング
		int		0x18
		jmp		short mainloop

; hootからコールされる
; inp8(HOOTPORT) = 0 → PC98DOS::Play
; inp8(HOOTPORT) = 2 → PC98DOS::Stop
; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)

vect_7f:
		pusha
		push	ds
		push	es
		mov		ax,cs
		mov		ds,ax
		mov		es,ax
		mov		dx,HOOTPORT
		in		al,dx
		cmp		al,HP_PLAY
		jz		short .play
		cmp		al,HP_STOP
		jz		short .fadeout
.ed:
		pop		es
		pop		ds
		popa
		iret

.play:	
		mov		ah,0x01		; 演奏停止
		int		0x61

		mov		cx,0x60		; vsync待ちでウェイト
.lp:
		nop
		call	.waitvsync
		loop	.lp

		mov		ah,0x06		; 曲データバッファアドレスを取得(DS:DX)
		int		0x61
		xor		bx,bx		; 標準入力
		mov		cx,0xffff	; データサイズ
		mov		ah,0x3f		; [DOS] read hundle
		int		0x21
		jc		.stop

		xor		ah,ah		; 演奏開始
		int		0x61
		jmp		short .ed

.stop:
		mov		ah,0x01		; 演奏停止
		int		0x61
		jmp		short .ed

.fadeout:
		mov		ax,0x0208	; フェードアウト
		int		0x61
		jmp		short .ed

.waitvsync:
		push	ax
		push	dx
		mov		dx,0xa0

.waitvsync_1:
		in		al,dx
		test	al,0x20
		jnz		.waitvsync_1

.waitvsync_2:
		in		al,dx
		test	al,0x20
		jz		.waitvsync_2
		pop		dx
		pop		ax
		ret

		ends
