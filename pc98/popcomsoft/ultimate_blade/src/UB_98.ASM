; PC-9801 Ultimate Blade
; (C) RuRuRu
; 2026/09/20 1st Release

; NASM -f bin [-DMIDI] UB_98.ASM -o UB_FM.COM / UB_MD.COM
BITS 16
CPU 186
ORG 100h

HOOTPORT equ 7e0h
HOOTFUNC equ 7e8h

start:
    cli
    push cs
    pop ds
    push cs
    pop es
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

    mov [driver+2],ax
    mov es,ax
    xor di,di
    mov dx,driverfile
    call loadfile
    jc fatal

    mov bx,1f40h
    mov cx,800h
    mov ah,0ah
    call api

%ifndef MIDI
    mov ah,0dh
    call api
    mov es,ax
    mov di,bx
    mov dx,effectfile
    call loadfile
    jc fatal

    mov ax,0701h
    call api
%endif
    mov ah,0ch
    call api
    mov [songptr],bx
%ifdef MIDI
    ; The game's entry 00 sends the GS reset and module setup before music.
    mov es,[driver+2]
    mov di,bx
    mov dx,songfile
    call loadfile
    jc fatal

    mov ax,1
    call api
    mov cx,256
    sti

.initializing:
    ; Entry 00 keeps running after setup
    ; the game waits before replacing it.
    hlt
    loop .initializing

    xor ax,ax
    call api
%endif
    mov ax,257fh
    mov dx,command
    int 21h
    mov dx,HOOTFUNC
    mov al,81h
    out dx,al
    sti
idle:
    jmp idle

fatal:
    mov ax,4c01h
    int 21h
    jmp fatal

api:
    pushf
    call far [cs:driver]
    ret

command:
    pusha
    push ds
    push es
    push cs
    pop ds

    mov dx,HOOTPORT
    in al,dx
    cmp al,2
    je stop

    test al,al
    jnz done

    mov dx,HOOTPORT+2
    in ax,dx
    test ax,ax
    jz stop

    cmp ax,39
    ja done

    dec ax
    push ax
    xor ax,ax
    call api
    pop ax
    mov bl,10
    div bl
    add ax,3030h        ; to ASCII
    mov [songfile+2],al ; make file name
    mov [songfile+3],ah
    mov es,[driver+2]
    mov di,[songptr]
    mov dx,songfile
    call loadfile
    jc done

    mov ax,1
    call api
    jmp done

stop:
    xor ax,ax
    call api

done:
    pop es
    pop ds
    popa
    iret


; DS:DX filename -> ES:DI
loadfile:
    mov ax,3d00h
    int 21h
    jc .return

    mov bx,ax
    push ds
    push es
    pop ds
    mov dx,di
    mov cx,1f40h
    mov ah,3fh
    int 21h
    pop ds
    pushf
    mov ah,3eh
    int 21h
    popf

.return:
    ret

driver: dw 0,0
songptr: dw 0
%ifdef MIDI
driverfile: db 'UBBGM_MD.COM',0
songfile: db 'MD00.BIN',0
%else
driverfile: db 'UBBGM_FM.COM',0
songfile: db 'FM00.BIN',0
effectfile: db 'UBEFF.BIN',0
%endif
align 16
times 1024 db 0
stack:
prgend:
