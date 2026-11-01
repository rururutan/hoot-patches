; Might and Magic III
; (C) RuRuRu
; 2026/10/21 1st Release
;
; nasm -f bin [-DMIDI=1] mm3_98.asm -o mm3[f/m]_98.com

bits 16
cpu 186

        org 100h
start:
        cli  
        cld  
        push cs
        pop  ds
        push cs
        pop  es
        mov  ax, cs
        mov  ss, ax
        mov  sp, stack_top

        mov  dx, 7e8h
        mov  al, 80h
        out  dx, al

        mov  bx, (program_end-$$+100h+15)/16
        mov  ah, 4ah
        int  21h
        jc   fatal

        mov  bx, 1000h
        mov  ah, 48h
        int  21h
        jc   fatal

        mov  [init_ptr+2], ax
        mov  [music_ptr+2], ax
        mov  es, ax
        xor  di, di
        xor  ax, ax
        mov  cx, 8000h
        rep  stosw
        mov  bx, 1000h
        mov  ah, 48h
        int  21h
        jc   fatal

        mov  [song_seg], ax
        mov  dx, driver_name
        mov  ax, 3d00h
        int  21h
        jc   fatal

        mov  bx, ax
        mov  ds, [init_ptr+2]
        xor  dx, dx
        mov  cx, 0ffffh
        mov  ah, 3fh
        int  21h
        push cs
        pop  ds
        jc   fatal

        cmp  ax, driver_size
        jne  fatal
        mov  ah, 3eh
        int  21h
        jc   fatal

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

        cmp   ax, 1fh
        jae   .done

        mov   ds, [song_seg]
        xor   dx, dx
        mov   cx, 0ffffh
        xor   bx, bx
        mov   ah, 3fh
        int   21h
        push  cs
        pop   ds
        jc    .done

        test  ax, ax
        jz    .done
        push  word [song_seg]          ; original API reads segment at BP+8.
        push  word 0                   ; offset argument (BP+6), original format starts at 0.
        call  far [music_ptr]
        add   sp, 4
        jmp   .done

.stop:
        call stop_music

.done:
        pop  es
        pop  ds
        popa 
        iret 

stop_music:
        push word 0                    ; music segment 0: synchronous sequence stop/key-off.
        push word 0
        call far [cs:music_ptr]
        add  sp, 4
        ret  

fatal:
        mov ax, 4c01h
        int 21h
        jmp fatal

init_ptr:
        dw 0,0
music_ptr:
        dw 6,0
song_seg:
        dw 0
%ifdef MIDI
driver_name:
        db  'roland.drv',0
driver_size equ 4566
%else
driver_name:
        db  'nec26k.drv',0
driver_size equ 4580
%endif

        align 16
        times 4096 db 0
stack_top:
program_end:

