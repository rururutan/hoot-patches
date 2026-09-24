; PC-9801 Ultima - The Savage Empire
; (C) RuRuRu
; 2026/09/20 1st Release

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
    mov al,80h		; disable hoot call
    out dx,al

    mov bx,((prgend-$$+100h)+15)/16
    mov ah,4ah
    int 21h
    jc fatal

    mov bx,200h
    mov ah,48h
    int 21h
    jc fatal

    mov [initptr+2],ax
    mov [playptr+2],ax
    mov [stopptr+2],ax
    mov es,ax
    mov dx,driverfile
    call loadfile
    jc fatal

    mov bx,1000h
    mov ah,48h
    int 21h
    jc fatal

    mov [songseg],ax
    mov ax,250ah
    mov dx,vsync_irq
    int 21h
    push word 0
    call far [initptr]
    push cs
    pop ds
    mov ax,257fh
    mov dx,vect_hoot
    int 21h

    mov dx,HOOTFUNC
    mov al,81h		; enable hoot call
    out dx,al

    sti
idle:
    jmp idle

fatal:
    mov ax,4c01h
    int 21h
    jmp fatal

vsync_irq:
    iret

vect_hoot:
    pusha
    push ds
    push es
    push cs
    pop ds
    mov dx,HOOTPORT
    in al,dx
    cmp al,2
    je stop

    cmp al,0
    jne done

    mov dx,HOOTPORT+2
    in ax,dx
    test ax,ax
    jz stop

    cmp ax,19
    ja done

    dec ax
    push ax
    call stopmusic
    pop ax
    mov bl,10
    div bl
    add ax,3030h
    mov [songfile+1],al
    mov [songfile+2],ah
    mov es,[songseg]
    mov dx,songfile
    call loadfile
    jc done

    push word [songseg]
    push word 0
    push word 2
    push word 1
    push word 0
    call far [playptr]
    push cs
    pop ds
    mov byte [playing],1
    jmp done

stop:
    call stopmusic

done:
    pop es
    pop ds
    popa
    iret

stopmusic:
    cmp byte [playing],0
    je .return
    call far [stopptr]
    push cs
    pop ds
    mov byte [playing],0
.return:
    ret

; DS:DX filename
; ES destination.
loadfile:
    mov ax,3d00h
    int 21h
    jc .return
    mov bx,ax
    push ds
    push es
    pop ds
    xor dx,dx
    mov cx,0ffffh
    mov ah,3fh
    int 21h
    pop ds
    pushf
    mov ah,3eh
    int 21h
    popf
.return:
    ret


initptr:
    dw 0,0
playptr:
    dw 6,0
stopptr:
    dw 9,0
songseg:
    dw 0
playing:
    db 0

driverfile:
    db 'FMDRV.BIN',0
songfile:
    db '000.BIN',0

align 16
    times 512 db 0
stack:
prgend:

