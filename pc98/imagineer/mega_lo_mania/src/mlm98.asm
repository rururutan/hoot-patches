; PC-9801 Mega lo Mania
; (C) RuRuRu
; 2026/09/24 1st Release

BITS 16
CPU 186

HOOTPORT equ 7e0h
HOOTFUNC equ 7e8h

DRIVER_INIT equ 0024h
DRIVER_PLAY equ 00e6h
DRIVER_STOP_MARK equ 01b4h
DRIVER_STOP_RESET equ 016fh
DRIVER_ALL_OFF equ 0187h
DRIVER_DATA_DELTA equ 00c8h
DRIVER_STATE equ 0ade4h
EXE_DRIVER_SEG equ 1e86h
EXE_ALLOC_PARAS equ 2df4h

        ORG 100h
start:
        cli  
        push cs
        pop  ds
        mov  ax, cs
        mov  ss, ax
        mov  sp, stack
        mov  dx, HOOTFUNC
        mov  al, 80h
        out  dx, al
        mov  bx, ((prgend-$$+100h)+15)/16
        mov  ah, 4ah
        int  21h
        jc   fatal

        mov  bx, 1000h
        mov  ah, 48h
        int  21h
        jc   fatal

        mov  [song_seg], ax
        mov  bx, EXE_ALLOC_PARAS
        mov  ah, 48h
        int  21h
        jc   fatal

        mov  [exe_seg], ax
        mov  [ovrparam], ax
        mov  [ovrparam+2], ax
        add  ax, EXE_DRIVER_SEG
        mov  [driver_seg], ax
        mov  [init_ptr+2], ax
        mov  [play_ptr+2], ax
        mov  [stop_mark_ptr+2], ax
        mov  [stop_reset_ptr+2], ax
        mov  [all_off_ptr+2], ax
        push cs
        pop  es
        mov  bx, ovrparam
        mov  dx, exe_file
        mov  ax, 4b03h
        int  21h
        jc   fatal

        call far [init_ptr]
        push cs
        pop  ds
        call silence_driver
        mov  ax, 257fh
        mov  dx, vect_hoot
        int  21h

        mov  dx, HOOTFUNC
        mov  al, 81h
        out  dx, al
        sti  
idle:
        jmp idle

fatal:
        mov ax, 4c01h
        int 21h
        jmp fatal

vect_hoot:
        pusha 
        push  ds
        push  es
        push  cs
        pop   ds
        mov   dx, HOOTPORT
        in    al, dx
        cmp   al, 2
        je    stop

        test  al, al
        jne   done

        mov   dx, HOOTPORT+2
        in    ax, dx
        test  ax, ax
        jz    stop

        cmp   ax, 3
        ja    done

        dec   ax
        mov   bx, ax
        shl   bx, 1
        mov   dx, [song_files+bx]
        push  dx
        call  stopmusic
        pop   dx
        mov   es, [song_seg]
        call  loadfile
        jc    done

        push  ds
        mov   ax, [driver_seg]
        add   ax, DRIVER_DATA_DELTA
        mov   ds, ax
        push  word [cs:song_seg]
        push  word 0
        call  far [cs:play_ptr]
        add   sp, 4
        pop   ds
        in    al, 0ah
        and   al, 0efh
        out   0ah, al
        push  cs
        pop   ds
        mov   byte [playing], 1
        jmp   done

stop:
        call stopmusic
done:
        pop  es
        pop  ds
        popa 
        iret 

stopmusic:
        cmp  byte [playing], 0
        je   .return
        call silence_driver
        push cs
        pop  ds
        mov  byte [playing], 0
.return:
        ret 

silence_driver:
        call far [all_off_ptr]
        call far [stop_mark_ptr]
        call far [stop_reset_ptr]
        push cs
        pop  ds
        mov  es, [driver_seg]
        mov  ax, es
        add  ax, DRIVER_DATA_DELTA
        mov  es, ax
        mov  byte [es:DRIVER_STATE], 3
        in   al, 0ah
        or   al, 10h
        out  0ah, al
        ret  

; DS:DX filename
; ES destination
loadfile:
        mov   ax, 3d00h
        int   21h
        jc    .return
        mov   bx, ax
        push  ds
        push  es
        pop   ds
        xor   dx, dx
        mov   cx, 0ffffh
        mov   ah, 3fh
        int   21h
        pop   ds
        pushf 
        mov   ah, 3eh
        int   21h
        popf  
.return:
        ret 

init_ptr:
        dw DRIVER_INIT,0
play_ptr:
        dw DRIVER_PLAY,0
stop_mark_ptr:
        dw DRIVER_STOP_MARK,0
stop_reset_ptr:
        dw DRIVER_STOP_RESET,0
all_off_ptr:
        dw DRIVER_ALL_OFF,0
driver_seg:
        dw 0
exe_seg:
        dw 0
song_seg:
        dw 0
playing:
        db 0
ovrparam:
        dw 0,0
exe_file:
        db 'MLM.EXE',0
song_op:
        db 'MMT.DAT',0
song_menu:
        db 'MPS.DAT',0
song_main:
        db 'MPM.DAT',0
song_files:
        dw    song_op,song_menu,song_main

        align 16
        times 512 db 0
stack:
prgend:
