; ストロベリー大戦略 music replayer for hoot pc98dos
;
; GAME.EXE   (Unpacked CRC32:2e322d35 Size:306112)
; MAIN98.EXE (Unpacked CRC32:638b676b Size:357104)

%include 'HOOT.INC'

int_hoot		equ	0x7f
; MZ header e_cparhdr = 03DCh, so (3C450h - 3DC0h) / 10h = 3869h.
driver_exe_delta	equ	0x3869
song_offset		equ	0x3e91
song_max_size		equ	0x8000
fm_voice_offset		equ	0x20e5
fm_voice_size		equ	0x1710
se_voice_offset		equ	0x3825
se_voice_size		equ	0x0668

; MAIN98.EXEには2つの音色が内包
voice_a_fm_seg_delta	equ	0x32c5
voice_a_fm_src_off	equ	0x0009
voice_b_fm_seg_delta	equ	0x3436
voice_b_fm_src_off	equ	0x0009
voice_a_se_seg_delta	equ	0x35a7
voice_a_se_src_off	equ	0x0009
voice_b_se_seg_delta	equ	0x360e
voice_b_se_src_off	equ	0x0001
game_voice_file_off	equ	0x408da

driver_init_play	equ	0x0088
driver_stop		equ	0x02cc

		ORG	0x0100
		USE16
		CPU	186

start:
		cli
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	ss, ax
		mov	sp, stack

		mov	dx, HOOTFUNC
		mov	al, HF_DISABLE
		out	dx, al

		mov	bx, program_end
		add	bx, 0x0f
		shr	bx, 4
		mov	ah, 0x4a
		int	0x21

		mov	dx, main_exe_name
		call	load_exe_overlay
		jc	fatal

		mov	[exe_seg], ax
		add	ax, driver_exe_delta
		mov	[driver_seg], ax

		; Refuse an incompatible image.  0088h is the init/play entry.
		mov	es, [driver_seg]
		cmp	word [es:driver_init_play], 0x509c	; pushf / push ax
		jne	fatal
		cmp	word [es:driver_init_play+2], 0x5153	; push bx / push cx
		jne	fatal
		cmp	word [es:driver_stop], 0x802e		; cmp byte [cs:...]
		jne	fatal

		mov	ax, [driver_seg]
		mov	[init_play_ptr+2], ax
		mov	[stop_ptr+2], ax

		mov	dx, vect_hoot
		mov	ax, 0x257f
		int	0x21

		mov	dx, HOOTFUNC
		mov	al, HF_ENABLE
		out	dx, al
		sti

.idle:
		hlt
		jmp	.idle

fatal:
		sti
.hang:
		hlt
		jmp	.hang

vect_hoot:
		pusha
		push	ds
		push	es
		mov	ax, cs
		mov	ds, ax
		mov	dx, HOOTPORT
		in	al, dx
		cmp	al, HP_PLAY
		je	.play
		cmp	al, HP_STOP
		je	.stop
.done:
		pop	es
		pop	ds
		popa
		iret

.play:
		mov	ds, [driver_seg]
		call	far [cs:stop_ptr]
		mov	dx, HOOTPORT+3	; bits 7..0 of the XML title code
		in	al, dx
		mov	dx, song_offset
		mov	cx, song_max_size
		xor	bx, bx
		mov	bl, al
		mov	ah, 0x3f
		int	0x21
		jc	.done

		mov	ds, [cs:driver_seg]
		mov	dx, HOOTPORT+4	; bits 23..16 of the XML title code
		in	al, dx
		call	install_voice
		jc	.done
		call	far [cs:init_play_ptr]
		jmp	.done

.stop:
		mov	ds, [driver_seg]
		call	far [cs:stop_ptr]
		jmp	.done

load_exe_overlay:
		push	es
		push	ds
		pusha
		mov	bp, sp

		mov	bx, -1
		mov	ah, 0x48
		int	0x21
		mov	ah, 0x48
		int	0x21
		mov	ss:[bp+0x0e], ax	; saved AX returned by POPA
		jc	.error

		push	ax		; relocation factor
		push	ax		; load segment
		mov	bx, sp
		mov	ax, ss
		mov	es, ax
		mov	ax, 0x4b03
		int	0x21
		jc	.free
		clc
		jmp	.finish

.free:
		xchg	ss:[bp+0x0e], ax
		mov	es, ax
		mov	ah, 0x49
		int	0x21
.error:
		stc
.finish:
		mov	sp, bp
		popa
		pop	ds
		pop	es
		ret

init_play_ptr:
		dw driver_init_play, 0
stop_ptr:
		dw driver_stop, 0
driver_seg:
		dw 0
exe_seg:
		dw 0
main_exe_name:	db 'MAIN98.EXE', 0
game_exe_name:	db 'GAME.EXE', 0

; 音色データの選択
; reg A: 0 = MAIN98.EXE A, 1 = MAIN98.EXE B, 2 = GAME.EXE
install_voice:
		push	es
		push	ds
		cmp	al, 2
		je	.bank_c
		cmp	al, 1
		je	.bank_b
		cmp	al, 0
		je	.bank_a
		pop	ds
		pop	es
		stc
		ret
.bank_c:
		pop	ds
		pop	es
		call	load_game_voice
		ret

.bank_a:
		mov	ax, [cs:exe_seg]
		add	ax, voice_a_fm_seg_delta
		mov	si, voice_a_fm_src_off
		mov	dx, voice_a_se_seg_delta
		mov	bp, voice_a_se_src_off
		jmp	.copy
.bank_b:
		mov	ax, [cs:exe_seg]
		add	ax, voice_b_fm_seg_delta
		mov	si, voice_b_fm_src_off
		mov	dx, voice_b_se_seg_delta
		mov	bp, voice_b_se_src_off
.copy:
		mov	ds, ax
		mov	es, [cs:driver_seg]
		mov	di, fm_voice_offset
		mov	cx, fm_voice_size
		cld
		rep movsb
		mov	ax, [cs:exe_seg]
		add	ax, dx
		mov	ds, ax
		mov	si, bp
		mov	di, se_voice_offset
		mov	cx, se_voice_size
		rep movsb
		pop	ds
		pop	es
		clc
		ret

; GAME.EXE内の音色データロード
load_game_voice:
		call	.install_a
		push	ds
		push	es
		push	bx
		push	cx
		push	dx
		push	cs
		pop	ds
		mov	dx, game_exe_name
		mov	ax, 0x3d00
		int	0x21
		jc	.error
		mov	bx, ax
		mov	cx, game_voice_file_off >> 16
		mov	dx, game_voice_file_off & 0xffff
		mov	ax, 0x4200
		int	0x21
		jc	.close_error
		mov	ds, [cs:driver_seg]
		mov	dx, fm_voice_offset
		mov	cx, fm_voice_size
		mov	ah, 0x3f
		int	0x21
		jc	.close_error
		cmp	ax, fm_voice_size
		jne	.close_error
		pushf
		mov	ah, 0x3e
		int	0x21
		popf
		jmp	.done
.close_error:
		mov	ah, 0x3e
		int	0x21
.error:
		stc
.done:
		pop	dx
		pop	cx
		pop	bx
		pop	es
		pop	ds
		ret
.install_a:
		push	es
		push	ds
		mov	ax, [cs:exe_seg]
		add	ax, voice_a_fm_seg_delta
		mov	si, voice_a_fm_src_off
		mov	dx, voice_a_se_seg_delta
		mov	bp, voice_a_se_src_off
		jmp	install_voice.copy

		align 16
		times 512 db 0xff
stack:
program_end:
