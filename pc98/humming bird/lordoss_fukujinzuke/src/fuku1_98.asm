
	HOOTPORT	equ		0x7e0

	ORG		0
	USE16
	CPU		186

start:			cli
				xor		ax, ax
				mov		ds, ax
				mov		ss, ax
				mov		sp, 0x1000

				; hoot ドライバ登録～
				mov		word [0x7f*4+0], vect_7f
				mov		[0x7f*4+2], cs

				mov		al, 0x42
				db		0x9a			; call far 0218:0000
				dw		0x0000
				dw		0x0218

				; メイン
				sti
.idle:			hlt
				hlt
				hlt
				hlt
				jmp		short .idle

				; hootからコールされる
				; inp8(HOOTPORT) = 0 → PC98VX::Play  ロード前
				; inp8(HOOTPORT) = 1 → PC98VX::Play  ロード後
				; inp8(HOOTPORT) = 2 → PC98VX::Stop
				; _code = inp8(HOOTPORT+2)～inp8(HOOTPORT+5)


vect_7f:		push	ax
				push	dx
				mov		dx, HOOTPORT
				in		al, dx
				cmp		al, 0
				je		short .stop
				cmp		al, 1
				je		short .play
				cmp		al, 2
				je		short .stop
.ed:			pop		dx
				pop		ax
				iret

.play:			mov		ax, 1
				mov		dx, 0x1000
				int		0x43
				jmp		short .ed

.stop:			mov		ax, 0
				int		0x43
				jmp		short .ed

	ends

