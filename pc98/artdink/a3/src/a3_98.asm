; PC-9801 A列車で行こう3 (要:Sound.ROM)
; (C) RuRuRu
; 2026/10/25 1st Release

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

        mov bx, 7000h
        mov ah, 48h
        int 21h
        jc  fatal

        mov [overlay], ax
        mov [overlay+2], ax
        mov es, ax

        ; Clear BSS
        mov dx, 7
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
        add  ax, 55b8h
        mov  [data_seg], ax
        mov  ax, [overlay]
        add  ax, 3506h
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
        cmp   ax, 37
        jae   .done

        mov   [cs:song], ax
        mov   word [cs:phrase], 0
        call  prepare_silent_init
        call  far [cs:init]
        call  seed_ssg_mixer
        call  far [cs:stop]
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
        mov   al, 80h                  ; defer hoot commands while compiling/enqueuing a phrase
        out   dx, al
        cmp   byte [cs:active], 0
        je    feed_done

        mov   ds, [cs:data_seg]
        push  word 0
        call  far [cs:status]
        add   sp, 2
        cmp   ax, 80h
        ja    feed_done

        mov   bx, [cs:song]
        imul  bx, bx, 8
        mov   si, [cs:tracks+bx]
        mov   dx, [cs:tracks+bx+6]     ; channel mask: bits 0..2 FM, 3..5 PSG
        mov   ax, dx
        xor   di, di
        mov   cx, 6
.count:
        shr ax, 1
        jnc .nextbit
        add di, 4
.nextbit:
        loop .count
        mov  ax, [cs:phrase]
        push dx
        mul  di
        pop  dx
        add  si, ax
        add  si, di
        sub  si, 2
        mov  bx, 20h
        mov  cx, 6
.args:
        test dx, bx
        jz   .empty
        push word [si]
        push word [si-2]
        sub  si, 4
        jmp  .next

.empty:
        push ds
        push word 7755h
.next:
        shr  bx, 1
        loop .args
.submit:
        push word 1
        call far [cs:play]
        add  sp, 26
submitted:
        mov  [cs:last_error], ax
        test ax, ax
        jnz  feed_finish
        inc  word [cs:phrase]
        mov  bx, [cs:song]
        imul bx, bx, 8
        mov  ax, [cs:phrase]
        cmp  ax, [cs:tracks+bx+2]
        jb   feed_done
        mov  ax, [cs:tracks+bx+4]
        cmp  ax, 0ffffh
        je   feed_finish
        mov  [cs:phrase], ax
        jmp  feed_done
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

; table base, phrase count, loop index (FFFF=one-shot), reserved
tracks:
        dw 07756h,6,00h,03fh
        dw 07816h,2,00h,03fh
        dw 077e6h,2,00h,03fh
        dw 07846h,5,00h,03fh
        dw 078beh,4,00h,03fh
        dw 0791eh,3,00h,03fh
        dw 07966h,13,00h,03fh
        dw 07aaah,2,00h,03fh
        dw 07a9eh,1,0ffffh,038h
        dw 07adah,1,0ffffh,01h
        dw 07adah,2,0ffffh,01h
        dw 07adah,3,0ffffh,01h
        dw 07ae6h,1,0ffffh,02h
        dw 07aeah,1,0ffffh,02h
        dw 07aeeh,1,0ffffh,02h
        dw 07af2h,1,0ffffh,04h
        dw 07af6h,1,0ffffh,02h
        dw 07afah,1,0ffffh,04h
        dw 07afeh,1,0ffffh,04h
        dw 07b02h,1,0ffffh,04h
        dw 07b06h,1,0ffffh,04h
        dw 07b0ah,1,0ffffh,04h
        dw 07b0eh,1,0ffffh,04h
        dw 07b12h,1,0ffffh,04h
        dw 07b16h,1,0ffffh,04h
        dw 07b1ah,1,0ffffh,04h
        dw 07b1eh,1,0ffffh,04h
        dw 07b22h,1,0ffffh,04h
        dw 07b26h,1,0ffffh,04h
        dw 07b2ah,1,0ffffh,07h
        dw 07b36h,1,0ffffh,07h
        dw 07b42h,1,0ffffh,02h
        dw 07b46h,1,0ffffh,02h
        dw 07b4ah,1,0ffffh,02h
        dw 07b4eh,1,0ffffh,02h
        dw 07b52h,1,0ffffh,02h
        dw 07b56h,1,0ffffh,038h
exe_name:
        db 'A3.EXE',0
overlay:
        dw 0,0
data_seg:
        dw 0
init:
        dw 0868h,0
play:
        dw 0aa2h,0
status:
        dw 0c34h,0
stop:
        dw 0d94h,0
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

