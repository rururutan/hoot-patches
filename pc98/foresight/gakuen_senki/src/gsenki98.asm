; PC-9801 学園戦記
; (C) RuRuRu
; 2026/10/16 1st Release

; MODE=0 FM, MODE=1 GS MIDI.

bits 16
cpu 186

        org 100h
start:
        cli 
        cld 
        mov ax, cs
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov sp, stack_top
        mov dx, 7e8h
        mov al, 80h
        out dx, al
        mov bx, (program_end-$$+100h+15)/16
        mov ah, 4ah
        int 21h
        jc  fatal

        mov  bx, 1800h
        mov  ah, 48h
        int  21h
        jc   fatal

        mov  [overlay], ax
        mov  [overlay+2], ax
        mov  es, ax
        xor  di, di
        xor  ax, ax
        mov  cx, 8000h
        rep  stosw
        mov  ax, es
        add  ax, 1000h
        mov  es, ax
        xor  di, di
        xor  ax, ax
        mov  cx, 4000h
        rep  stosw
        push cs
        pop  es
        mov  bx, overlay
        mov  dx, exe_name
        mov  ax, 4b03h
        int  21h
        jc   fatal

        mov  ax, [overlay]
        add  ax, 10a2h
        mov  [init_ptr+2], ax
        call far [init_ptr]

        mov  ah, 0                     ; API-0 initialize driver
        int  52h

        mov  bx, 1000h
        mov  ah, 48h
        int  21h
        jc   fatal

        mov  [music_seg], ax
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

command:
        pusha 
        push  ds
        push  es
        cld   

        mov   dx, 7e0h
        in    al, dx
        cmp   al, 2
        je    .stop

        test  al, al
        jnz   .done

        mov   ah, 3                      ; API-3 Stop
        int   52h

        mov   dx, 7e2h
        in    ax, dx
        cmp   ax, 10h
        jb    .done

        cmp   ax, 1dh
        jae   .done

        mov   ds, [cs:music_seg]
        xor   dx, dx
        mov   cx, 4000h
        xor   bx, bx
        mov   ah, 3fh
        int   21h
        jc    .done

        test  ax, ax
        jz    .done

        xor   si, si
        mov   ax, 0200h+MODE           ; API-2 Play
        int   52h                      ; AL=0 FM / 1 MPU98
        jmp   .done

.stop:
        mov ah, 3                      ; API-3 Stop
        int 52h

.done:
        pop  es
        pop  ds
        popa 
        iret 

fatal:
        mov ax, 4c01h
        int 21h
        jmp fatal

overlay:
        dw 0,0
music_seg:
        dw 0
init_ptr:
        dw 3180h,0
exe_name:
        db    'GAME.EXE',0

        align 16
        times 4096 db 0
stack_top:
program_end:

