; PC-9801 MS Field 2'93
;   code based MLALF_98.COM by Silver-Hirame
; (C) RuRuRu
; 2026/10/22 1st Release

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

        mov bx, 2600h
        mov ah, 48h
        int 21h
        jc  fatal

        mov [overlay], ax
        mov [overlay+2], ax
        mov bx, 2
.clear:
        mov  es, ax
        push ax
        xor  di, di
        xor  ax, ax
        mov  cx, 8000h
        rep  stosw
        pop  ax
        add  ax, 1000h
        dec  bx
        jnz  .clear
        mov  es, ax
        xor  di, di
        xor  ax, ax
        mov  cx, 3000h
        rep  stosw
        push cs
        pop  es
        mov  bx, overlay
        mov  dx, exe_name
        mov  ax, 4b03h
        int  21h
        jc   fatal

        mov  ax, [overlay]
        add  ax, 2063h                 ; original Music Lalf segment
        mov  [init_ptr+2], ax
        mov  [load_ptr+2], ax
        mov  [play_ptr+2], ax
        mov  [stop_ptr+2], ax
        call far [init_ptr]
        call far [stop_ptr]
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

        call  far [cs:stop_ptr]
        mov   dx, 7e2h
        in    ax, dx
        cmp   ax, 10h
        jb    .done

        cmp   ax, 47h
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

        push  ds
        xor   dx, dx
        push  dx
        call  far [cs:load_ptr]
        add   sp, 4
        call  far [cs:play_ptr]
        jmp   .done

.stop:
        call far [cs:stop_ptr]
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
        dw 0417h,0
load_ptr:
        dw 052ah,0
play_ptr:
        dw 05b7h,0
stop_ptr:
        dw 05e4h,0
exe_name:
        db    'MAIN.EXE',0

        align 16
        times 4096 db 0
stack_top:
program_end:

