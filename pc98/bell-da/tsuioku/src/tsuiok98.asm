; PC-9801 追憶
; (C) RuRuRu
; 2026/10/21 1st Release

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

        mov bx, 7800h
        mov ah, 48h
        int 21h
        jc  fatal

        mov [overlay], ax
        mov [overlay+2], ax
        mov bx, ax
        mov bp, 7800h
.clear:
        mov  es, bx
        xor  di, di
        xor  ax, ax
        mov  cx, 8
        rep  stosw
        inc  bx
        dec  bp
        jnz  .clear

        push cs
        pop  es
        mov  dx, exe_name
        mov  bx, overlay
        mov  ax, 4b03h
        int  21h
        jc   fatal

        mov  ax, [overlay]
        mov  [voices_ptr+2], ax
        add  ax, 0913h
        mov  [init_ptr+2], ax
        mov  [play_ptr+2], ax
        mov  [stop_ptr+2], ax
        mov  ax, [overlay]
        add  ax, 2300h
        mov  [music_seg], ax
        mov  dx, sound_name
        mov  ax, 3d00h
        int  21h
        jc   fatal

        mov  bx, ax
        mov  ds, [music_seg]
        xor  dx, dx
        mov  cx, 2e00h
        mov  ah, 3fh
        int  21h
        push cs
        pop  ds
        jc   fatal

        cmp  ax, 2e00h
        jne  fatal

        mov  ah, 3eh
        int  21h
        jc   fatal

        mov  es, [music_seg]
        xor  di, di
        call far [voices_ptr]
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
        push  cs
        pop   ds
        cld   
        mov   dx, 7e0h
        in    al, dx
        cmp   al, 2
        je    .stop

        test  al, al
        jnz   .done

        call  far [stop_ptr]
        mov   dx, 7e2h
        in    ax, dx
        cmp   ax, 10h
        jb    .done

        cmp   ax, 23h
        jae   .done

        mov   ds, [music_seg]
        xor   dx, dx
        xor   bx, bx
        mov   cx, 5000h
        mov   ah, 3fh
        int   21h
        push  cs
        pop   ds
        jc    .done

        test  ax, ax
        jz    .done

        call  far [init_ptr]           ; timer/header/instrument setup.
        call  far [play_ptr]
        jmp   .done

.stop:
        call far [stop_ptr]

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
voices_ptr:
        dw 90d4h,0
init_ptr:
        dw 0,0
play_ptr:
        dw 254h,0
stop_ptr:
        dw 216h,0
music_seg:
        dw 0
exe_name:
        db 'TUIOKU.EXE',0
sound_name:
        db 'SOUND.DAT',0

        align 16
        times 4096 db 0
stack_top:
program_end:

