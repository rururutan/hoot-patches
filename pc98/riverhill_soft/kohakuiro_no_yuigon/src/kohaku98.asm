;
; Riverhillsoft 琥珀色の遺言
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
    xor ax,ax
    mov ss,ax
    mov sp,1000h

    mov ds,ax
    mov dx,HOOTFUNC
    mov al,80h
    out dx,al
    mov word [7fh*4],command
    mov [7fh*4+2],cs
    call silence

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

    cmp ax,14
    ja done

    push ax
    call silence
    pop ax
    mov dx,7e2h
    out dx,al
    jmp done

loaded:
    mov ax,3000h
    mov es,ax
    cmp word [es:0],061eh
    jne done

    call 3000h:0
    jmp done

stop:
    call silence
    jmp done

; temporary code...
silence:
    cli
    in al,0ah
    or al,10h
    out 0ah,al
    mov word [14h*4],stopped_irq
    mov [14h*4+2],cs
    mov bx,2730h
    call opn
    mov bx,2800h
    call opn
    inc bl
    call opn
    inc bl
    call opn
    mov bx,0800h
    call opn
    inc bh
    call opn
    inc bh
    call opn
    mov bx,07bfh
    call opn
    ret


opn:
    mov dx,188h
.wait:
    in al,dx
    test al,80h
    jnz .wait
    mov al,bh
    out dx,al
.wait_data:
    in al,dx
    test al,80h
    jnz .wait_data
    add dx,2
    mov al,bl
    out dx,al
    ret
stopped_irq:
    push ax
    mov al,20h
    out 8,al
    out 0,al
    pop ax
    iret
