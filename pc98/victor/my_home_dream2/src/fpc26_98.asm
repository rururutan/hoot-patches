; FPC26.COM : Classic Road 4 / My Home Dream 2(PC-9801) player for hoot pc98dos
; (C) RuRuRu
; 08/10/03 1st Release
; 26/10/04 Fix initialize

%include 'hoot.inc'

USE16
CPU     186

VOICE_HANDLE    equ 0x05
BUFFER_SIZE     equ 0x8000

        ORG     0x0100

start:
        cli
        mov     ax,cs
        mov     ds,ax
        mov     es,ax
        mov     ss,ax
        mov     sp,stack_top
        sti

        ; The game calls API 08h once while initializing its sound layer.
        mov     ah,0x08
        int     0xeb

        ; SOUND26.DAT is file handle 5 in the XML. API 09h copies it into
        ; FPC26-owned storage, so the load buffer can later hold song data.
        mov     bx,VOICE_HANDLE
        mov     ah,0x3f
        mov     cx,BUFFER_SIZE
        mov     dx,load_buffer
        int     0x21
        jc      fatal
        or      ax,ax
        jz      fatal

        mov     cx,cs
        mov     dx,load_buffer
        mov     ah,0x09
        int     0xeb

        mov     ax,0x257f
        mov     dx,vect_7f
        int     0x21

mainloop:
        hlt
        jmp     short mainloop

; hoot command interrupt:
;   HOOTPORT   = 0: play, 2: stop
;   HOOTPORT+5 = 0: BGM, nonzero: SSG sound effect
vect_7f:
        pusha
        push    ds
        push    es
        push    cs
        pop     ds
        push    cs
        pop     es

        sti

        mov     dx,HOOTPORT
        in      al,dx
        cmp     al,HP_PLAY
        je      short .play
        cmp     al,HP_STOP
        je      short .stop
        jmp     short .done

.play:
        call    stop_current

        mov     ah,0x3f
        xor     bx,bx
        mov     cx,BUFFER_SIZE
        mov     dx,load_buffer
        int     0x21
        jc      short .done
        or      ax,ax
        jz      short .done

        ; The game saves byte +2 before calling the registration API.
        mov     al,[load_buffer+2]
        mov     [song_id],al

        ; Delete only the song registered by the preceding play. Deleting
        ; every type-1 entry with AL=ffh disturbs FPC26's registration table
        ; after switching to a different song ID.
.clear_retry:
        mov     al,[registered_id]
        cmp     al,0xff
        je      short .register
        mov     ah,0x06
        int     0xeb
        jnc     short .cleared
        cmp     al,0x01
        je      short .clear_retry
        jmp     short .done
.cleared:
        mov     byte [registered_id],0xff

.register:
        mov     cx,cs
        mov     dx,load_buffer
        mov     ah,0x01
        int     0xeb
        mov     al,[song_id]
        mov     [registered_id],al

        mov     dx,HOOTPORT+5
        in      al,dx
        mov     [play_mode],al
        mov     dl,0x7f
        or      al,al
        jz      short .start_play
        mov     dl,0x80
.start_play:
        mov     al,[song_id]
        mov     ah,0x02
        int     0xeb
        jmp     short .done

.stop:
        call    stop_current
.done:
        pop     es
        pop     ds
        popa
        iret

stop_current:
        mov     al,[play_mode]
        cmp     al,0xff
        je      short .done
        or      al,al
        mov     ax,0x0300
        jz      short .call
        mov     ax,0x03ff
.call:
        int     0xeb
        mov     byte [play_mode],0xff
.done:
        ret

fatal:
        mov     ax,0x4c01
        int     0x21

song_id:
        db      0
play_mode:
        db      0xff
registered_id:
        db      0xff

        times 0x100 db 0
stack_top:
        align   0x10
load_buffer:
