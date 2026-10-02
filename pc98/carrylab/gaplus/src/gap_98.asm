; PC-9801 Gaplus (C) Carry-lab
; (C) RuRuRu
; 2026/10/03 1st Release

;  FM driver  : 0000:8F00
;  Music data : 2000:0000

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
        mov es, ax
        mov ss, ax
        mov sp, 7000h
        mov word [7fh*4], command
        mov word [7fh*4+2], 0
        mov word [8*4], timer
        mov word [8*4+2], 0
        mov word [904ch], 2000h
        mov di, 904fh
        mov al, 0ffh
        mov cx, 6
        rep stosb
        call 90b4h
        mov ax, 77h
        mov es, ax
        call 90b4h
        xor ax, ax
        mov es, ax

        ; Original init seeds the PSG mixer cache at 9064h with BFh.
        ; Set both cache and register 7: noise must remain disabled.
        mov al, 0bfh
        call 9544h
        call music_stop

        ; Same PIT channel 0 divisor and mode as the game (2020h, mode 2).
        mov al, 34h
        out 77h, al
        mov al, 20h
        out 71h, al
        out 71h, al
        in al, 2
        and al, 0feh
        out 2, al
        mov dx, HOOTFUNC
        mov al, 81h
        out dx, al
        sti
idle:
        mov ax, 9801h
        int 18h
        jmp idle

timer:
        push ax
        call 8f03h
        mov al, 20h
        out 0, al
        pop ax
        iret

command:
        pusha
        push ds
        push es
        xor ax, ax
        mov ds, ax
        mov es, ax
        mov dx, HOOTPORT
        in al, dx
        cmp al, 2
        je stop

        test al, al
        jnz done

        mov dx, 7e2h
        in ax, dx
        test ax, ax
        jz stop

        cmp ax, 2
        jb done

        cmp ax, 28
        ja done

        push ax
        call music_stop
        pop ax

        mov bx, 3
        mul bx
        add ax, 8f03h
        mov bx, ax
        call bx
        jmp done

stop:
        call music_stop

done:
        pop es
        pop ds
        popa
        iret


music_stop:
        cli
        mov word [9072h], 0
        mov word [97e2h], 0
        mov byte [9076h], 0ffh
        mov byte [97e6h], 0ffh
        mov byte [904eh], 0
        call 92d3h
        mov byte [904eh], 1
        call 92d3h
        mov byte [904eh], 0
        ret
