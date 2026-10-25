;
; PC-9801 Lenam (c)Hertz
;  SWORD.EXE (CRC32:0xeb2fb0df)
; (C) RuRuRu
; 2026/10/03 1st Release
;

BITS 16
CPU 186
ORG 100h

HOOTPORT       equ 07e0h
HOOTFUNC       equ 07e8h
EXE_ALLOC      equ 03ddbh

MIDI_SEGMENT   equ 00f92h
FM_RESET       equ 0e8c1h
FM_PLAY        equ 0e905h
FM_STOP        equ 0e9e5h
FM_INSTALL     equ 0ec27h
MIDI_RESET     equ 00009h
MIDI_INSTALL   equ 0002bh
MIDI_STOP      equ 000d4h
MIDI_PLAY      equ 00182h

start:
    cli
    push cs
    pop ds
    mov ax,cs
    mov ss,ax
    mov sp,stack

    mov dx,HOOTFUNC
    mov al,80h
    out dx,al
    mov bx,((prgend-$$+100h)+15)/16
    mov ah,4ah
    int 21h
    jc fatal

    mov bx,1000h
    mov ah,48h
    int 21h
    jc fatal

    mov [song_seg],ax
    mov bx,EXE_ALLOC
    mov ah,48h
    int 21h
    jc fatal

    mov [exe_seg],ax
    mov [overlay_param],ax
    mov [overlay_param+2],ax
%ifdef MIDI
    add ax,MIDI_SEGMENT
%endif
    mov [reset_ptr+2],ax
    mov [install_ptr+2],ax
    mov [stop_ptr+2],ax
    mov [play_ptr+2],ax
    push cs
    pop es
    mov bx,overlay_param
    mov dx,exe_file
    mov ax,4b03h
    int 21h
    jc fatal

    call far [reset_ptr]
    call far [install_ptr]
    push cs
    pop ds
    mov ax,257fh
    mov dx,vect_hoot
    int 21h
    mov dx,HOOTFUNC
    mov al,81h
    out dx,al
    sti

.idle:
    jmp .idle

fatal:
    mov ax,4c01h
    int 21h
    jmp fatal

vect_hoot:
    pusha
    push ds
    push es
    push cs
    pop ds
    mov dx,HOOTPORT
    in al,dx
    cmp al,2
    je .stop

    test al,al
    jne .done

    mov dx,HOOTPORT+2
    in ax,dx
    test ax,ax
    jz .stop

    cmp ax,SONG_FIRST
    jb .done

    cmp ax,SONG_LAST
    ja .done

    sub ax,SONG_FIRST
    mov [song_index],al
    call stopmusic
    mov es,[song_seg]
    call loadstdin
    jc .done

%ifdef MIDI
    push word 1
    push word [song_seg]
    push word 0
    call far [play_ptr]
    add sp,6
%else
    mov ax,0ffh
    cmp byte [song_index],0
    jne .repeat_ready
    mov ax,1
.repeat_ready:
    push ax
    push word 0
    push word [song_seg]
    push word 0
    call far [play_ptr]
    add sp,8
%endif
    push cs
    pop ds
    mov byte [playing],1
    jmp .done

.stop:
    call stopmusic

.done:
    pop es
    pop ds
    popa
    iret

stopmusic:
    cmp byte [playing],0
    je .return
    call far [stop_ptr]
    push cs
    pop ds
    mov byte [playing],0
.return:
    ret

loadstdin:
    push ds
    push es
    pop ds
    xor dx,dx
    xor bx,bx
    mov cx,0ffffh
    mov ah,3fh
    int 21h
    pop ds
.return:
    ret

%ifdef MIDI
reset_ptr:   dw MIDI_RESET,0
install_ptr: dw MIDI_INSTALL,0
stop_ptr:    dw MIDI_STOP,0
play_ptr:    dw MIDI_PLAY,0
%else
reset_ptr:   dw FM_RESET,0
install_ptr: dw FM_INSTALL,0
stop_ptr:    dw FM_STOP,0
play_ptr:    dw FM_PLAY,0
%endif

exe_seg: dw 0
song_seg: dw 0
playing: db 0
song_index: db 0
overlay_param: dw 0,0
exe_file: db 'SWORD.EXE',0

SONG_FIRST equ 10h
SONG_LAST  equ 1eh

align 16
    times 512 db 0
stack:
prgend:
