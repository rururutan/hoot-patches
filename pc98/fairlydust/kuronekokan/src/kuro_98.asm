; PC-9801 黒猫館 KURO.EXE(CRC32:0x59af0e44)演奏
; (C) RuRuRu
; 2026/10/10 1st Release

BITS 16
CPU 186
HOOTPORT equ 7e0h
HOOTFUNC equ 7e8h

        ORG 100h
start:
        cli 
        cld 
        mov ax, cs
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov sp, stack_top
        mov dx, HOOTFUNC
        mov al, 80h
        out dx, al
        mov bx, ((program_end-$$+100h)+15)/16
        mov ah, 4ah
        int 21h
        jc  fatal

        mov bx, 2000h
        mov ah, 48h
        int 21h
        jc  fatal

        mov [image_seg], ax
        mov [overlay], ax
        mov [overlay+2], ax
        mov dx, 2
.clear:
        mov  es, ax
        push ax
        xor  ax, ax
        xor  di, di
        mov  cx, 8000h
        rep  stosw
        pop  ax
        add  ax, 1000h
        dec  dx
        jnz  .clear

        push cs
        pop  es
        mov  bx, overlay
        mov  dx, exe_name
        mov  ax, 4b03h
        int  21h
        jc   fatal

        mov  ax, [image_seg]
        add  ax, 0b29h
        mov  [game_ds], ax
        mov  ax, [image_seg]
        mov  [init_ptr+2], ax
        mov  [stop_ptr+2], ax
        mov  [play_ptr+2], ax

        mov  es, ax
        xor  di, di
        mov  si, trampolines
        mov  cx, trampolines_end-trampolines
        rep  movsb
        mov  bx, 1000h
        mov  ah, 48h
        int  21h
        jc   fatal

        mov  [music_seg], ax
        mov  ax, 257fh
        mov  dx, command
        int  21h
        mov  ds, [cs:game_ds]
        call far [cs:init_ptr]
        call far [cs:stop_ptr]
        mov  dx, HOOTFUNC
        mov  al, 81h
        out  dx, al
        sti  
.idle:
        mov ax, 9801h
        int 18h
        jmp .idle

fatal:
        mov ax, 4c01h
        int 21h
        jmp fatal

command:
        pusha 
        push  ds
        push  es
        cld   
        sti   
        mov   ds, [cs:game_ds]
        call  far [cs:stop_ptr]
        mov   dx, HOOTPORT
        in    al, dx
        test  al, al
        jnz   .done

        mov  ds, [cs:music_seg]
        xor  dx, dx
        xor  bx, bx
        mov  cx, 0ffffh
        mov  ah, 3fh
        int  21h
        jc   .done

        test ax, ax
        jz   .done
        mov  dx, ds
        xor  cx, cx
        mov  ds, [cs:game_ds]
        call far [cs:play_ptr]
.done:
        pop  es
        pop  ds
        popa 
        iret 

trampolines:
        db 0e8h
        dw 9ab8h-3
        db 0cbh
        db 0e8h
        dw 9c9eh-7
        db 0cbh
        db 51h,52h,0e8h
        dw 9b69h-13
        db 83h,0c4h,04h,0e8h
        dw 9c8dh-19
        db 0cbh
trampolines_end:

image_seg:
        dw 0
game_ds:
        dw 0
music_seg:
        dw 0
overlay:
        dw 0,0
init_ptr:
        dw 0,0
stop_ptr:
        dw 4,0
play_ptr:
        dw 8,0
exe_name:
        db    'KURO.EXE',0

        align 16
        times 2048 db 0
stack_top:
program_end:

