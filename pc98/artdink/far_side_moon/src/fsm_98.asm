; PC-9801 Far side moon (要:Sound.ROM)
; (C) RuRuRu
; 2026/10/21 1st Release

bits 16
cpu 186
        org 100h
start:
        cli 
        cld 
        mov ax, cs
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov sp, stack_top
        mov dx, 7e8h
        mov al, 80h
        out dx, al
        mov bx, (program_end-$$+100h+15)/16
        mov ah, 4ah
        int 21h
        jc  fatal

        mov bx, 6000h
        mov ah, 48h
        int 21h
        jc  fatal

        mov [overlay], ax
        mov [overlay+2], ax
        mov es, ax
        mov dx, 6
.clear:
        xor  ax, ax
        xor  di, di
        mov  cx, 8000h
        rep  stosw
        mov  ax, es
        add  ax, 1000h
        mov  es, ax
        dec  dx
        jnz  .clear

        push cs
        pop  es
        mov  ax, 4b03h
        mov  dx, exe_name
        mov  bx, overlay
        int  21h
        jc   fatal

        mov  ax, [overlay]
        add  ax, 4ea0h
        mov  [data_seg], ax
        mov  ax, [overlay]
        add  ax, 34d5h
        mov  [init+2], ax
        mov  [play+2], ax
        mov  [status+2], ax
        mov  [stop+2], ax
        xor  ax, ax
        mov  es, ax
        mov  word [es:41h*4], 3000h
        mov  word [es:41h*4+2], 0e800h ; Sound BIOS PSG frequency table base
        mov  ds, [data_seg]
        call prepare_silent_init
        call far [cs:init]
        call seed_ssg_mixer
        test ax, ax
        jnz  fatal

        call far [cs:stop]             ; AH=19h: clear queues / key-off
        push cs
        pop  ds
        mov  dx, command
        mov  ax, 257fh
        int  21h

        mov  dx, 7e8h
        mov  al, 81h
        out  dx, al
        sti  
idle:
        call feed
        mov dx, 7e1h
        out dx, al
        jmp idle

prepare_silent_init:
        pushf 
        cli   
        push  ax
        push  bx
        push  dx
        push  es
        mov   ax, 0cc00h
        mov   es, ax
        cmp   word [es:30a5h], 08b3h
        je    .patch

        cmp   word [es:30a5h], 00b3h
        jne   fatal

.patch:
        mov byte [es:30a6h], 0
        mov bh, 08h
        mov dx, 0188h
.channel:
        in   al, dx
        test al, 80h
        jnz  .channel

        mov  al, bh
        out  dx, al
.wait:
        in   al, dx
        test al, 80h
        jnz  .wait

        add  dx, 2
        xor  al, al
        out  dx, al
        sub  dx, 2
        inc  bh
        cmp  bh, 0bh
        jb   .channel

        pop  es
        pop  dx
        pop  bx
        pop  ax
        popf 
        ret  

seed_ssg_mixer:
        test ax, ax
        jnz  .done

        push ax
        push bx
        push es
        xor  ax, ax
        mov  es, ax
        les  bx, [es:05e0h]
        mov  byte [es:bx+0238h], 0bfh
        mov word [es:bx+00d4h], 0808h
        mov byte [es:bx+00d6h], 08h
        pop es
        pop bx
        pop ax
.done:
        ret 

command:
        pusha 
        push  ds
        push  es
        cld   
        mov   dx, 7e8h
        mov   al, 80h
        out   dx, al
        mov   ds, [cs:data_seg]
        mov   dx, 7e0h
        in    al, dx
        cmp   al, 2
        je    .stop

        test  al, al
        jnz   .done

        call  far [cs:stop]
        mov   byte [cs:active], 0
        mov   dx, 7e2h
        in    ax, dx
        cmp   ax, 28
        jae   .done

        mov   [cs:song], ax
        mov   word [cs:phrase], 0
        call  prepare_silent_init
        call  far [cs:init]
        call  seed_ssg_mixer
        call  far [cs:stop]
        cmp   word [cs:song], 0
        je    .ready

        cmp   word [cs:song], 2
        ja    .ready

        mov   ax, 1106h                ; same PSG noise/mixer setup as native 33FB:008E/01A2
        mov   bl, 3
        int   0d2h
        mov   ax, 1107h
        mov   bl, 0a7h
        int   0d2h
.ready:
        mov byte [cs:active], 1
        jmp .done

.stop:
        mov  byte [cs:active], 0
        call far [cs:stop]

.done:
        mov  dx, 7e8h
        mov  al, 81h
        out  dx, al
        pop  es
        pop  ds
        popa 
        iret 

feed:
        pusha 
        push  ds
        push  es
        mov   dx, 7e8h
        mov   al, 80h
        out   dx, al
        cmp   byte [cs:active], 0
        je    feed_done

        mov   ds, [cs:data_seg]
        push  word 0
        call  far [cs:status]
        add   sp, 2
        cmp   ax, 100h
        ja    feed_done

        mov   ax, [cs:song]
        mov   si, [cs:phrase]
        cmp   ax, 3
        jae   .effect

        mov   bx, 812ah
        cmp   ax, 0
        je    .bgm

        mov   bx, 824ah
        cmp   ax, 1
        jne   .third

        cmp   si, 12
        jb    .bgm

        sub   si, 12
        mov   bx, 8382h
        jmp   .bgm

.third:
        mov bx, 836ah

.bgm:
        imul si, si, 24
        add  si, bx
        add  si, 22
        mov  cx, 12
.args:
        push word [si]
        sub  si, 2
        loop .args
        jmp  .submit

.effect:
        push ds
        push word 8526h
        push ds
        push word 8526h
        push ds
        push word 8526h
        sub  ax, 3
        imul si, ax, 12
        add  si, 83fah+10
        mov  cx, 6
.effect_args:
        push word [si]
        sub  si, 2
        loop .effect_args
.submit:
        push word 1
        call far [cs:play]
        add  sp, 26
submitted:
        mov  [cs:last_error], ax
        test ax, ax
        jnz  feed_finish
        mov  ax, [cs:song]
        cmp  ax, 3
        jae  feed_finish
        inc  word [cs:phrase]
        cmp  ax, 2
        je   feed_short
        cmp  ax, 1
        je   feed_second
        cmp  word [cs:phrase], 12
        jb   feed_done
        mov  word [cs:phrase], 0
        jmp  feed_done
feed_second:
        cmp word [cs:phrase], 17
        jb  feed_done
        mov word [cs:phrase], 12
        jmp feed_done
feed_short:
        cmp word [cs:phrase], 6
        jb  feed_done
        mov word [cs:phrase], 1
        jmp feed_done
feed_finish:
        mov byte [cs:active], 0
feed_done:
        mov  dx, 7e8h
        mov  al, 81h
        out  dx, al
        pop  es
        pop  ds
        popa 
feed_return:
        ret 

fatal:
        mov ax, 4c01h
        int 21h
        jmp fatal

exe_name:
        db 'ESDF.EXE',0
overlay:
        dw 0,0
data_seg:
        dw 0
init:
        dw 086ah,0
play:
        dw 0a42h,0
status:
        dw 0bd4h,0
stop:
        dw 0d34h,0
song:
        dw 0
phrase:
        dw 0
last_error:
        dw 0
active:
        db    0

        align 16
        times 8192 db 0
stack_top:
program_end:

