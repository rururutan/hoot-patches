; PC-9801 Zero - 第4のユニット4
; (C) RuRuRu
; 2026/10/22 1st Release

bits 16
cpu 186

%define GAME 4
%define DATA_REL 0x807
%define BRIDGE 0x6368
%define N_INIT 0x4bd3
%define N_STOP 0x589a
%define N_PLAY 0x58c6

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

        mov bx, 3000h
        mov ah, 48h
        int 21h
        jc  fatal
        mov [overlay], ax
        mov [overlay+2], ax
        mov [init_ptr+2], ax
        mov [stop_ptr+2], ax
        mov [play_ptr+2], ax
        add ax, DATA_REL
        mov [data_seg], ax

        ; Clear BSS
        mov  ax, [overlay]
        mov  es, ax
        xor  ax, ax
        xor  di, di
        mov  cx, 8000h
        rep  stosw
        mov  ax, es
        add  ax, 1000h
        mov  es, ax
        xor  ax, ax
        mov  cx, 8000h
        rep  stosw
        mov  ax, es
        add  ax, 1000h
        mov  es, ax
        xor  ax, ax
        mov  cx, 8000h
        rep  stosw
        push cs
        pop  es
        mov  dx, exe_name
        mov  bx, overlay
        mov  ax, 4b03h
        int  21h
        jc   fatal

; TFU4.EXE is the supplied EXEPACK-expanded MZ executable.
; DOS overlay loading applies its relocation table directly.
        mov  ax, [overlay]
        mov  es, ax
        mov  di, BRIDGE
        mov  si, bridge_blob
        mov  cx, bridge_end-bridge_blob
        rep  movsb
        push cs
        pop  ds
        mov  dx, voice_name
        mov  ax, 3d00h
        int  21h
        jc   fatal

        mov  bx, ax
        mov  ds, [cs:data_seg]
        mov  dx, 0xe7fa
        mov  cx, 256
        mov  ah, 3fh
        int  21h
        jc   fatal

        cmp  ax, 256
        jne  fatal

        mov  ah, 3eh
        int  21h
        mov  word [0xe8fe], 0ffffh     ; original game: music enabled (00313h / 014E6h)
        call far [cs:init_ptr]
        call far [cs:stop_ptr]
        push cs
        pop  ds
        mov  dx, callback
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

callback:
        pusha 
        push  ds
        push  es
        cld   
        mov   ds, [cs:data_seg]
        mov   dx, 7e0h
        in    al, dx
        cmp   al, 2
        je    .stop

        test  al, al
        jnz   .done

        call  far [cs:stop_ptr]

; Native stop masks IRQ14 before the shared song buffer is replaced.
%if GAME = 3
        mov dx, 9000h
%else
; Native event decoder uses near pointers internally: music must share DS.
        mov dx, 9000h
%endif
        xor  bx, bx
        mov  cx, 4000h
        mov  ah, 3fh
        int  21h
        jc   .done
        test ax, ax
        jz   .done
        mov  bx, ds
        mov  ds, [cs:data_seg]
        mov  ax, 3                     ; native mode 3 = loop, mode 2 = one-shot
        mov  dx, 7e3h
        in   al, dx
        test al, 1                     ; title code bit 8 disables looping
        mov  ax, 3
        jz   .mode
        dec  ax
.mode:
        push ax
%if GAME = 4
        push bx
        push word 9000h
%else
        push word 9000h
%endif
        call far [cs:play_ptr]
%if GAME = 4
        add sp, 6
%else
        add sp, 4
%endif
        jmp .done
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
        jmp $
; These bridges replace the unused game startup code in the loaded image.
; init/stop: CALL near native_routine ; RETF
; play: PUSH BP ; MOV BP,SP ; copy C arguments past the far return address ;
;       CALL near native_play ; ADD SP,argument_bytes ; POP BP ; RETF
; No change to the original file, native ISR, instrument tables or song data.
bridge_blob:
        db 0e8h
        dw N_INIT-(BRIDGE+($-bridge_blob)+2)
        db 0cbh
        db 0e8h
        dw N_STOP-(BRIDGE+($-bridge_blob)+2)
        db 0cbh
        db 55h,89h,0e5h
%if GAME = 4
        db 0ffh,76h,0ah ; push word [bp+10] (mode)
%endif
        db 0ffh,76h,08h ; mode (3) / segment (4)
        db 0ffh,76h,06h ; offset
        db 0e8h
        dw N_PLAY-(BRIDGE+($-bridge_blob)+2)
%if GAME = 4
        db 83h,0c4h,06h
%else
        db 83h,0c4h,04h
%endif
        db 5dh,0cbh
bridge_end:

init_ptr:
        dw BRIDGE,0
stop_ptr:
        dw BRIDGE+4,0
play_ptr:
        dw BRIDGE+8,0
overlay:
        dw 0,0
data_seg:
        dw 0
voice_name:
        db 'VOICE.DAT',0
exe_name:
        db    'TFU4.EXE',0

        align 16
        times 1024 db 0
stack_top:
program_end:

