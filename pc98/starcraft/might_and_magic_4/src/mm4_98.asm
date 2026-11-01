; Might and Magic IV
; (C) RuRuRu
; 2026/10/21 1st Release

bits 16
cpu 186
%ifdef VERSION21
main_paras  equ 5900h
main_cs     equ 32a7h
main_init   equ 9515h
main_play   equ 95b1h
main_stop   equ 9681h
main_buffer equ 88d6h
%else
main_paras  equ 4000h
main_cs     equ 05b7h
main_init   equ 0b8bah
main_play   equ 0b94ch
main_stop   equ 0ba1ch
main_buffer equ 0ac7bh
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

%ifdef VERSION21
        mov  bx, 1800h
        mov  dx, intro_name
        call load_overlay
        add  ax, 07ddh
        mov  [banks+12], ax
%endif
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

        cmp   ax, 1eh
        jae   .done

%ifdef VERSION21
        xor bx, bx
        cmp ax, 10h                    ; mm4theme.m uses the intro EXE's original driver.
        jne .bank
        mov bx, 12
.bank:
        cmp  bx, [current_bank]
        je   .loaded

        push bx
        call far [exit_ptr]            ; restore prior IRQ14 before installing another driver.
        pop  bx
        mov  [current_bank], bx
        call select_bank
        call far [init_ptr]
        call stop_music
.loaded:
%endif
        mov  ax, [play_ptr+2]
        mov  dx, [music_buffer]
        mov  ds, ax
        mov  cx, 0c00h                 ; original buffer has C3Fh bytes before init code.
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
        dw 0,main_init,main_play,main_stop,main_buffer
%ifdef VERSION21
        dw 9585h
%else
        dw 0b920h
%endif
%ifdef VERSION21
        dw 0,0ad05h,0ada1h,0ae71h,0a0c6h,0ad75h
main_name:
        db 'XEEN.DAT',0
intro_name:
        db 'XEEN.EXE',0
%else
main_name:
        db 'XEEN.EXE',0
%endif

        align 16
        times 4096 db 0
stack_top:
program_end:

