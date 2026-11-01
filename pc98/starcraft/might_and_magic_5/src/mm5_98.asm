; PC-9801/9821 Might and Magic V: original
; (C) RuRuRu
; 2026/10/21 1st Release

bits 16
cpu 186

%ifdef VERSION21
main_paras   equ 5b00h
main_cs      equ 36eeh
main_init    equ 0a0f2h
main_play    equ 0a18eh
main_stop    equ 0a25eh
main_buffer  equ 8982h
intro_paras  equ 2900h
intro_cs     equ 1173h
intro_init   equ 0c2f4h
intro_play   equ 0c390h
intro_stop   equ 0c460h
intro_buffer equ 0ab84h
main_exit    equ 0a162h
intro_exit   equ 0c364h
%else
main_paras   equ 3a00h
main_cs      equ 133dh
main_init    equ 0bc97h
main_play    equ 0bd33h
main_stop    equ 0be03h
main_buffer  equ 0b058h
intro_paras  equ 2200h
intro_cs     equ 0c0bh
intro_init   equ 0c56bh
intro_play   equ 0c607h
intro_stop   equ 0c6d7h
intro_buffer equ 0ad74h
main_exit    equ 0bd07h
intro_exit   equ 0c5dbh
%endif

        org 100h
start:
        cli  
        cld  
        mov  ax, cs
        mov  ds, ax
        mov  es, ax
        mov  ss, ax
        mov  sp, stack_top

        mov  dx, 7e8h
        mov  al, 80h
        out  dx, al

        mov  bx, (program_end-$$+100h+15)/16
        mov  ah, 4ah
        int  21h
        jc   fatal

        mov  bx, main_paras
        mov  dx, main_name
        call load_overlay
        add  ax, main_cs
        mov  [banks], ax
        mov  bx, intro_paras
        mov  dx, intro_name
        call load_overlay
        add  ax, intro_cs
        mov  [banks+12], ax

        xor  bx, bx
        call select_bank

        call far [init_ptr]

        call stop_music

        mov  dx, command
        mov  ax, 257fh
        int  21h

        mov  dx, 7e8h
        mov  al, 81h
        out  dx, al
        sti  
idle:
        mov ax, 9801h
        int 18h
        jmp idle

; BX    = paragraphs
; DS:DX = filename
; Return AX = load segment.
load_overlay:
        push dx
        push bx
        mov  ah, 48h
        int  21h
        jc   fatal

        mov  [overlay], ax
        mov  [overlay+2], ax
        mov  bp, ax
        pop  bx

.clear:
        mov  es, bp
        xor  di, di
        xor  ax, ax
        mov  cx, 8
        rep  stosw
        inc  bp
        dec  bx
        jnz  .clear

        push cs
        pop  es
        pop  dx
        mov  bx, overlay
        mov  ax, 4b03h
        int  21h
        jc   fatal

        mov  ax, [overlay]
        ret  

; BX = descriptor byte offset.
;      Each bank has segment/init/play/stop/buffer/shutdown.
select_bank:
        mov ax, [banks+bx]
        mov [init_ptr+2], ax
        mov [play_ptr+2], ax
        mov [stop_ptr+2], ax
        mov ax, [banks+bx+2]
        mov [init_ptr], ax
        mov ax, [banks+bx+4]
        mov [play_ptr], ax
        mov ax, [banks+bx+6]
        mov [stop_ptr], ax
        mov ax, [banks+bx+8]
        mov [music_buffer], ax
        mov ax, [banks+bx+10]
        mov [exit_ptr], ax
        mov ax, [init_ptr+2]
        mov [exit_ptr+2], ax
        ret 

command:
        pusha 
        push  ds
        push  es
        push  cs
        pop   ds
        cld   
        mov   dx, 7e0h
        in    al, dx
        cmp   al, 2
        je    .stop

        test  al, al
        jnz   .done

        call  stop_music
        mov   dx, 7e2h
        in    ax, dx
        cmp   ax, 10h
        jb    .done

        cmp   ax, 31h
        jae   .done

        xor   bx, bx
        cmp   ax, 15h                  ; first five files belong to INTRO.CC.
        jae   .bank

        mov   bx, 12
.bank:
        cmp  bx, [current_bank]
        je   .loaded

        push bx
        call far [exit_ptr]
        pop  bx
        mov  [current_bank], bx
        call select_bank
        call far [init_ptr]
        call stop_music

.loaded:
        mov ax, [play_ptr+2]
        mov dx, [music_buffer]
        mov ds, ax
        mov cx, 0c00h                  ; main buffer: C3Fh bytes before init code.
        cmp word [cs:current_bank], 0
        je  .read

        mov cx, 1700h
.read:
        xor  bx, bx
        mov  ah, 3fh
        int  21h
        push cs
        pop  ds
        jc   .done

        cmp  ax, 12
        jb   .done

        call far [play_ptr]
        jmp  .done

.stop:
        call stop_music

.done:
        pop  es
        pop  ds
        popa 
        iret 

stop_music:
        call far [cs:stop_ptr]
        ret  

fatal:
        mov ax, 4c01h
        int 21h
        jmp fatal

overlay:
        dw 0,0
init_ptr:
        dw 0,0
play_ptr:
        dw 0,0
stop_ptr:
        dw 0,0
exit_ptr:
        dw 0,0
music_buffer:
        dw 0
current_bank:
        dw 0
banks:
        dw 0,main_init,main_play,main_stop,main_buffer,main_exit
        dw 0,intro_init,intro_play,intro_stop,intro_buffer,intro_exit
main_name:
        db 'XEEN.DAT',0
intro_name:
        db    'XEEN.EXE',0

        align 16
        times 4096 db 0
stack_top:
program_end:

