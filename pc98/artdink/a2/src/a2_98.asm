; PC-9801 A列車で行こう2 (要:Sound.ROM)
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

        ; Clear BSS
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
        add  ax, 4fbdh
        mov  [data_seg], ax
        mov  ax, [overlay]
        add  ax, 199eh
        mov  [init+2], ax
        mov  [play+2], ax
        mov  [status+2], ax
        mov  [stop+2], ax
        xor  ax, ax
        mov  es, ax
        mov  word [es:41h*4], 3000h
        mov  word [es:41h*4+2], 0e800h ; Sound BIOS PSG frequency table base
        mov  ds, [data_seg]
        mov  word [209ah], 100h        ; MS C stack probe lower bound for our private stack
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
        cmp   ax, 15
        jae   .done
        cmp   ax, 6
        jb    .valid
        cmp   ax, 10
        jb    .done

.valid:
        mov  [cs:song], ax
        mov  word [cs:phrase], 0
        call prepare_silent_init
        call far [cs:init]
        call seed_ssg_mixer
        call far [cs:stop]
.ready:
        mov word [cs:count], 1
        mov word [cs:repeat_at], 0ffffh
        cmp word [cs:song], 0
        jne .not_title
        mov word [cs:count], 14
        mov word [cs:repeat_at], 1
.not_title:
        cmp  word [cs:song], 10
        jb   .prepared
        call load_music
.prepared:
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

; Feed ahead of playback with >=512 bytes free in each 640-byte BIOS ring.
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
        cmp   ax, 80h
        ja    feed_done
        cmp   word [cs:song], 10
        jae   .external
        cmp   word [cs:song], 0
        jne   .effect
        mov   si, [cs:phrase]
        imul  si, si, 24
        add   si, 1d1eh+22
        mov   cx, 12
.args:
        push word [si]
        sub  si, 2
        loop .args
        jmp  .submit
.effect:
        mov cx, 5
.empty:
        push ds
        push word 1e82h
        loop .empty
        mov  si, [cs:song]
        dec  si
        shl  si, 2
        add  si, 1e6eh
        push word [si+2]
        push word [si]
        jmp  .submit
.external:
        mov  si, [cs:phrase]
        imul si, si, 24
        add  si, ptrs+22
        mov  cx, 12
.extargs:
        push word [cs:si]
        sub  si, 2
        loop .extargs
.submit:
        push word 1
        call far [cs:play]
        add  sp, 26
submitted:
        mov  [cs:last_error], ax
        test ax, ax
        jnz  feed_finish
        inc  word [cs:phrase]
        mov  ax, [cs:phrase]
        cmp  ax, [cs:count]
        jb   feed_done
        mov  ax, [cs:repeat_at]
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

load_music:
        push ds
        push es
        push cs
        pop  ds
        push cs
        pop  es
        xor  bx, bx
        mov  dx, music
        mov  cx, 1024
        mov  ah, 3fh
        int  21h
        jc   fatal
        cmp  ax, 1024
        jae  fatal
        cmp  ax, 2
        jb   fatal
        mov  bx, music
        add  bx, ax
        mov  si, music
        mov  di, ptrs
        xor  dx, dx
.scan:
        cmp   si, bx
        jae   fatal
        cmp   byte [si], 0b1h          ; native MU file terminator, not an MML string
        je    .end
        cmp   dx, 60
        jae   fatal
        mov   ax, si
        stosw 
        mov   ax, cs
        stosw 
        inc   dx
.next:
        cmp   si, bx
        jae   fatal
        lodsb 
        test  al, al
        jnz   .next
        jmp   .scan
.end:
        lea  ax, [si+2]
        cmp  ax, bx
        jne  fatal
        cmp  byte [si+1], 0
        jne  fatal
        mov  ax, dx
        xor  dx, dx
        mov  cx, 6
        div  cx
        test dx, dx
        jnz  fatal
        cmp  ax, 2
        jb   fatal
        mov  [count], ax
        mov  word [repeat_at], 0
        pop  es
        pop  ds
        ret  

fatal:
        mov ax, 4c01h
        int 21h
        jmp fatal

exe_name:
        db 'A2.EXE',0
overlay:
        dw 0,0
data_seg:
        dw 0
init:
        dw 0887h,0
play:
        dw 0a66h,0
status:
        dw 0c06h,0
stop:
        dw 0d66h,0
song:
        dw 0
phrase:
        dw 0
last_error:
        dw 0
active:
        db 0
count:
        dw 0
repeat_at:
        dw 0
ptrs:
        times 240 db 0
music:
        times 1024 db 0

        align 16
        times 16384 db 0
stack_top:
program_end:

