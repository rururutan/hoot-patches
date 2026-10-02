;
; Riverhillsoft Princess Minerva (MIDI)
; (C) RuRuRu
; 2026/09/26 1st Release
;

BITS 16
CPU 186
ORG 0

HOOTPORT equ 07e0h
HOOTFUNC equ 07e8h

start:
    cli
    cld
    mov dx,HOOTFUNC
    mov al,80h
    out dx,al

    xor ax,ax
    mov ss,ax
    mov sp,1000h
    mov ds,ax
    mov word [7fh*4],command
    mov [7fh*4+2],cs
    mov word [40h*4],0
    mov word [40h*4+2],100h
    mov ax,0201h ; AL=init, AH=1 FM, AH=2 MPU-98
    int 40h

    mov dx,HOOTFUNC
    mov al,81h
    out dx,al
    sti

idle:
    mov ax,9801h
    int 18h
    jmp idle

command:
    pusha
    push ds
    push es

    xor ax,ax
    mov ds,ax
    mov dx,HOOTPORT
    in al,dx
    cmp al,0
    je select

    cmp al,1
    je loaded

    cmp al,2
    je stop

done:
    pop es
    pop ds
    popa
    iret

select:
    mov dx,7e2h
    in ax,dx
    test ax,ax
    jz stop

    cmp ax,3fh
    jb done

    cmp ax,70h
    ja done

    push ax
    mov ax,3
    int 40h
    pop ax
    mov dx,7e2h
    out dx,al
    jmp done

loaded:
    cmp word [6d00h],14h
    jne done

    mov ax,2
    int 40h
    jmp done

stop:
    mov ax,3
    int 40h
    jmp done
