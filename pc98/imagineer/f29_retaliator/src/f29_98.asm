; PC-9801 F29 Retaliator (C) Imagneer
;   RTmusic1.8. pc98vx boot wrapper.
; (C) RuRuRu
; 2026/09/23 1st Release
;
        BITS 16
        CPU 186
        ORG 600h

        HOOTPORT equ 7e0h
        HOOTFUNC equ 7e8h

start:
        cli
        cld
        xor ax, ax
        mov ds, ax
        mov ss, ax
        mov sp, 0f000h
        mov word [7fh*4], command
        mov word [7fh*4+2], 0
        mov word [50h*4], 14h
        mov word [50h*4+2], 2000h
        mov word [14h*4], stopped_irq
        mov word [14h*4+2], 0

        in al, 2
        and al, 0fbh
        out 2, al

        call reset_driver
        call stopmusic

        mov dx, HOOTFUNC
        mov al, 81h
        out dx, al
        sti
idle:
        mov ax, 9801h
        int 18h
        jmp idle

command:
        pusha
        push ds
        push es
        cld
        mov dx, HOOTPORT
        in al, dx
        cmp al, 2
        je stop

        test al, al
        jnz done

        mov dx, HOOTPORT+2
        in ax, dx
        test ax, ax
        jz stop

        cmp ax, 37
        ja done

        push ax
        call stopmusic
        call reset_driver
        pop ax
        cmp al, 30
        ja .bgm

        mov ah, 8
        mov dl, 1
        int 50h
        jmp done

.bgm:
        sub al, 30
        mov ah, 7
        int 50h
        jmp done

stop:
        call stopmusic

done:
        pop es
        pop ds
        popa
        iret

reset_driver:
        cli
        mov ax, 4000h
        mov ds, ax
        mov ax, 2000h
        mov es, ax
        xor si, si
        xor di, di
        mov cx, 671bh
        rep movsb
        mov ax, 0ff01h	; Initialize
        int 50h
        ret

stopmusic:
        xor ax, ax
        int 50h
        mov ax, 0ff00h
        int 50h
        ret

stopped_irq:
        push ax
        mov al, 20h
        out 8, al
        out 0, al
        pop ax
        iret
