; PC-9801 Stratego hoot patch
; (C) RuRuRu
; 2026/10/04 1st Release

BITS 16
CPU 186

HOOTPORT equ 07e0h
HOOTFUNC equ 07e8h

EXE_PARAS equ 3600h
CODE_SEG_DELTA equ 1cf2h
DATA_SEG_DELTA equ 3138h
MUSIC_BUFFER equ 23aah
MUSIC_MAX equ 1f40h
SOUND_ENABLE equ 1a0ch
API_PLAY equ 49d8h
API_STOP equ 4a00h
API_INIT equ 8b75h
API_PREPARE equ 8b91h
SONG_FIRST equ 10h
SONG_LAST equ 17h

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

        mov  bx, EXE_PARAS
        mov  ah, 48h
        int  21h
        jc   fatal

        mov  [exe_seg], ax
        mov  [overlay_param], ax
        mov  [overlay_param+2], ax
        add  ax, CODE_SEG_DELTA
        mov  [init_ptr+2], ax
        mov  [prepare_ptr+2], ax
        mov  [play_ptr+2], ax
        mov  [stop_ptr+2], ax
        mov  ax, [exe_seg]
        add  ax, DATA_SEG_DELTA
        mov  [data_seg], ax
        push cs
        pop  es
        mov  bx, overlay_param
        mov  dx, exe_file
        mov  ax, 4b03h
        int  21h
        jc   fatal

        push cs
        pop  ds
        mov es, [data_seg]
        mov word [es:SOUND_ENABLE], 0ffffh
        call far [prepare_ptr]
        push cs
        pop  ds
        call far [init_ptr]
        push cs
        pop  ds
        mov  ax, 257fh
        mov  dx, vect_hoot
        int  21h
        mov  dx, HOOTFUNC
        mov  al, 81h
        out  dx, al
        sti  
.idle:
        jmp .idle

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
        sti  

        mov  dx, HOOTPORT
        in   al, dx
        cmp  al, 2
        je   .stop

        test al, al
        jne  .done

        mov  dx, HOOTPORT+2
        in   ax, dx
        test ax, ax
        jz   .stop

        cmp  ax, SONG_FIRST
        jb   .done

        cmp  ax, SONG_LAST
        ja   .done

        call stop_music
        call loadstdin
        jc   .done

        mov  ds, [data_seg]
        call far [cs:play_ptr]
        push cs
        pop  ds
        jmp  .done

.stop:
        call stop_music

.done:
        pop  es
        pop  ds
        popa 
        iret 

stop_music:
        mov  ds, [data_seg]
        call far [cs:stop_ptr]
        push cs
        pop  ds
        ret  

loadstdin:
        mov  ds, [data_seg]
        mov  dx, MUSIC_BUFFER
        xor  bx, bx
        mov  cx, MUSIC_MAX
        mov  ah, 3fh
        int  21h
        push cs
        pop  ds
        ret  

init_ptr:
        dw API_INIT,0
prepare_ptr:
        dw API_PREPARE,0
play_ptr:
        dw API_PLAY,0
stop_ptr:
        dw API_STOP,0
exe_seg:
        dw 0
data_seg:
        dw 0
overlay_param:
        dw 0,0
exe_file:
        db    'STRATEGO.EXE',0
        align 16
        times 512 db 0
stack:
prgend:

