; Hell-Ogre (c)Zigo Watt.
; (C) RuRuRu
; 2026/10/06 1st Release

BITS 16
CPU 186

HOOTPORT       equ 07e0h
HOOTFUNC       equ 07e8h
BUFFER_SIZE    equ 4000h

        ORG 100h

start:
        cli
        push    cs
        pop     ds
        mov     ax,cs
        mov     ss,ax
        mov     sp,stack

        ; Load voice
        mov     dx,voice_name
        mov     ax,3d00h
        int     21h
        jc      fatal

        mov     bx,ax
        mov     dx,music_buffer
        mov     cx,2500h
        mov     ah,3fh
        int     21h

        pushf
        push    ax
        mov     ah,3eh
        int     21h
        pop     ax
        popf
        jc      fatal

        cmp     ax,2500h
        jne     fatal

        mov     si,music_buffer
        mov     byte [voice_index],0
.voice_loop:
        mov     al,[voice_index]
        mov     ah,02h
        int     40h
        add     si,80h
        inc     byte [voice_index]
        cmp     byte [voice_index],74
        jb      .voice_loop

        mov     ax,0907h
        mov     bl,0b8h
        int     40h

        mov     dx,HOOTFUNC
        mov     al,80h
        out     dx,al

        mov     ax,257fh
        mov     dx,vect_hoot
        int     21h

        mov     dx,HOOTFUNC
        mov     al,81h
        out     dx,al
        sti
.idle:
        jmp     .idle

fatal:
        mov     ax,4c01h
        int     21h
        jmp     fatal

vect_hoot:
        pusha
        push    ds
        push    es
        push    cs
        pop     ds
        push    cs
        pop     es
        cld

        mov     dx,HOOTPORT
        in      al,dx
        cmp     al,2
        je      .stop
        test    al,al
        jne     .done

        mov     ah,03h
        int     40h

        mov     ah,3fh
        xor     bx,bx
        mov     cx,BUFFER_SIZE
        mov     dx,music_buffer
        int     21h
        jc      .done
        cmp     ax,21
        jb      .done
        mov     [last_size],ax
        cmp     word [music_buffer],0abfdh
        jne     .done

        mov     ah,03h ; stop
        int     40h

        mov     dx,[music_buffer+7]
        mov     ah,01h
        int     40h

        mov     dx,1
        mov     al,4
        mov     ah,06h
        int     40h
        mov     al,5
        mov     ah,06h
        int     40h

        mov     word [track_table],ds
        mov     si,music_buffer+9
        mov     di,track_table+2
        mov     cx,6
.offset_loop:
        lodsw
        shl     ax,1
        add     ax,music_buffer
        stosw
        loop    .offset_loop

        mov     cx,[last_size]
        sub     cx,7
        mov     si,music_buffer+7
        mov     di,music_buffer
        rep     movsb

        mov     bx,track_table
        mov     ah,05h
        int     40h
        jmp     .done

.stop:
        mov     ah,03h
        int     40h
.done:
        pop     es
        pop     ds
        popa
        iret

last_size:      dw 0
voice_index:    db 0
voice_name:     db 'SHOT.VIC',0
track_table:    times 7 dw 0

align 16
music_buffer:   times BUFFER_SIZE db 0
align 16
                times 512 db 0
stack:

