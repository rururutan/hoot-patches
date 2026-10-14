; PC-9801 神の聖都
; (C) RuRuRu
; 2026/10/05 1st Release

BITS 16
CPU 186

HOOTPORT   equ 07e0h
HOOTFUNC   equ 07e8h

PUTBGM     equ 07d0h
DRIVER_SEG equ 2000h
WORK_SEG   equ 3000h
HEADER_SEG equ 37feh
MUSIC_SEG  equ 3800h

TRAMP_INIT equ 0f000h
TRAMP_PLAY equ 0f020h
TRAMP_STOP equ 0f030h
TRAMP_SETUP equ 0f040h
TRAMP_TABLE equ 0f100h
TRAMP_VOICE_SIZE equ 0f110h

        ORG 600h

start:
        cli  
        cld  
        xor  ax, ax
        mov  ds, ax
        mov  ss, ax
        mov  sp, 1000h
        mov  word [7fh*4], command
        mov  word [7fh*4+2], 0
        call install_trampolines
        call far [cs:init_ptr]
        mov  byte [cs:playing], 0
        mov  dx, HOOTFUNC
        mov  al, 81h
        out  dx, al
        sti  
.idle:
        mov ax, 9801h
        int 18h
        jmp .idle

command:
        pusha 
        push  ds
        push  es
        cld   
        xor   ax, ax
        mov   ds, ax
        mov   dx, HOOTPORT
        in    al, dx
        cmp   al, 2
        je    .stop

        test  al, al
        jnz   .done

        mov   dx, HOOTPORT+2
        in    ax, dx
        test  ax, ax
        jz    .stop

        cmp   ax, 33
        ja    .done

        push  ax
        call  stop_music
        pop   ax

        xor   ah, ah
        mov   dx, PUTBGM+2
        out   dx, ax                   ; BGM number
        xor   ax, ax
        mov   dx, PUTBGM+4
        out   dx, ax                   ; Destination offset
        mov   ax, HEADER_SEG
        mov   dx, PUTBGM+6
        out   dx, ax                   ; Destination segment
        mov   al, 20h
        mov   dx, PUTBGM
        out   dx, al                   ; Synchronous transfer
        in    al, dx
        test  al, al
        jnz   .done

        call  install_song_table
        jc    .done

        call  far [cs:setup_ptr]
        call  far [cs:play_ptr]
        mov   byte [cs:playing], 1
        jmp   .done

.stop:
        call stop_music
.done:
        pop  es
        pop  ds
        popa 
        iret 

stop_music:
        cmp  byte [cs:playing], 0
        je   .return
        call far [cs:stop_ptr]
        mov  byte [cs:playing], 0
.return:
        ret 

install_trampolines:
        push ds
        push es
        push cs
        pop  ds
        mov  ax, DRIVER_SEG
        mov  es, ax
        mov  si, init_trampoline
        mov  di, TRAMP_INIT
        mov  cx, init_trampoline_end-init_trampoline
        rep  movsb
        mov  si, play_trampoline
        mov  di, TRAMP_PLAY
        mov  cx, play_trampoline_end-play_trampoline
        rep  movsb
        mov  si, stop_trampoline
        mov  di, TRAMP_STOP
        mov  cx, stop_trampoline_end-stop_trampoline
        rep  movsb
        mov  si, setup_trampoline
        mov  di, TRAMP_SETUP
        mov  cx, setup_trampoline_end-setup_trampoline
        rep  movsb
        pop  es
        pop  ds
        ret  

init_trampoline:
        mov  ax, WORK_SEG
        mov  ds, ax
        mov  ax, 212ch
        call ax              ; Detect FM board and install timer IRQ
        mov  ax, 0069h
        call ax              ; Initialize the music driver
        retf 

init_trampoline_end:
play_trampoline:
        mov  ax, WORK_SEG
        mov  ds, ax
        mov  bx, MUSIC_SEG
        mov  ax, 006fh
        call ax
        retf 

play_trampoline_end:
stop_trampoline:
        mov  ax, WORK_SEG
        mov  ds, ax
        mov  ax, 0069h
        call ax
        retf 

stop_trampoline_end:
setup_trampoline:
        mov  si, TRAMP_TABLE
        mov  bx, [cs:TRAMP_VOICE_SIZE]
        mov  ax, 006ch
        call ax
        retf 

setup_trampoline_end:
install_song_table:
        push ds
        push es
        mov  ax, HEADER_SEG
        mov  ds, ax
        cmp  word [0], 414bh           ; "KA"
        jne  .bad

        cmp  word [2], 494dh           ; "MI"
        jne  .bad

        mov  ax, DRIVER_SEG
        mov  es, ax
        mov  ax, [4]
        mov  [es:TRAMP_VOICE_SIZE], ax
        mov  si, 6
        mov  di, TRAMP_TABLE
        mov  cx, 6
        rep  movsw
        clc  
        jmp  .return

.bad:
        stc 
.return:
        pop es
        pop ds
        ret 

init_ptr:
        dw TRAMP_INIT,DRIVER_SEG
play_ptr:
        dw TRAMP_PLAY,DRIVER_SEG
stop_ptr:
        dw TRAMP_STOP,DRIVER_SEG
setup_ptr:
        dw TRAMP_SETUP,DRIVER_SEG
playing:
        db 0

