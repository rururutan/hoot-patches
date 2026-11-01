; PC-9801 Dragon Wars
; (C) RuRuRu
; 2026/10/21 1st Release

bits 16
cpu 186

        org 100h
start:
        cli
        cld
        mov ax,cs
        mov ds,ax
        mov es,ax
        mov ss,ax
        mov sp,stack_top

        mov dx,7e8h
        mov al,80h
        out dx,al

        mov bx,((program_end-$$+100h)+15)/16
        mov ah,4ah
        int 21h
        jc fatal

        mov bx,6500h
        mov ah,48h
        int 21h
        jc fatal

        mov [overlay],ax
        mov [overlay+2],ax

        ; Clear BSS
        mov dx,6
.clear:
        mov es,ax
        push ax
        xor ax,ax
        xor di,di
        mov cx,8000h
        rep stosw
        pop ax
        add ax,1000h
        dec dx
        jnz .clear

        mov es,ax
        xor ax,ax
        xor di,di
        mov cx,2800h
        rep stosw
        push cs
        pop es
        mov bx,overlay
        mov dx,exe_name
        mov ax,4b03h
        int 21h
        jc fatal

        mov ax,[overlay]
        add ax,4e56h
        mov [play_ptr+2],ax
        mov [stop_ptr+2],ax
        call far [stop_ptr]
        mov dx,command
        mov ax,257fh
        int 21h

        mov dx,7e8h
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
        cld
        mov dx,7e0h
        in al,dx
        cmp al,2
        je .stop

        test al,al
        jnz .done

        call far [cs:stop_ptr]
        mov dx,7e2h
        in ax,dx
        cmp ax,9
        jae .done

        push ax
        call far [cs:play_ptr] ; near song number argument, far C entry.
        add sp,2
        jmp .done

.stop:
        call far [cs:stop_ptr]

.done:
        pop es
        pop ds
        popa
        iret

fatal:
        mov ax,4c01h
        int 21h
        jmp fatal

overlay dw 0,0
play_ptr dw 0326h,0
stop_ptr dw 0222h,0
exe_name db 'DRAGON.EXE',0

align 16
times 4096 db 0
stack_top:
program_end:
