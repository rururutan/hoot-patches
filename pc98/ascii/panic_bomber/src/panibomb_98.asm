; PC-9821 Bomberman: Panic Bomber for hoot pc98vx driver

BITS 16
CPU 186
ORG 600h

HOOTPORT       equ 07e0h
HOOTFUNC       equ 07e8h
HOOT_VECTOR    equ 7fh
DRIVER_SEGMENT equ 1400h

start:
        cli
        cld
        xor     ax,ax
        mov     ds,ax
        mov     ss,ax
        mov     sp,0f000h

        mov     word [HOOT_VECTOR*4],command
        mov     word [HOOT_VECTOR*4+2],0

        mov     word [40h*4],0
        mov     word [40h*4+2],DRIVER_SEGMENT

        mov     ax,0101h        ; initialize
        int     40h

        xor     ax,ax           ; get buffer (fixed)
        int     40h

        mov     dx,HOOTFUNC
        mov     al,81h
        out     dx,al
        sti

.idle:
        mov     ax,9801h
        int     18h
        jmp     short .idle

command:
        pusha
        push    ds
        push    es
        cld
        mov     dx,HOOTPORT
        in      al,dx
        cmp     al,2
        je      short .stop
        cmp     al,1
        jne     short .done

        call    stop_music
        mov     ax,2               ; play BGM
        int     40h
        jmp     short .done

.stop:
        call    stop_music
.done:
        pop     es
        pop     ds
        popa
        iret

stop_music:
        mov     ax,3               ; stop
        int     40h
        ret

        times 512 db 0
