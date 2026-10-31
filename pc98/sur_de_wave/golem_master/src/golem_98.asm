; PC-98 Golem Master BIOS6Z.COM
; (C) RuRuRu
; 2026/10/30 1st Release

bits 16
cpu 186

        org 100h
start:
        cli  
        cld  
        push cs
        pop  ds
        push cs
        pop  es
        mov  ax, cs
        mov  ss, ax
        mov  sp, stack_top

        mov  dx, 7e8h
        mov  al, 80h
        out  dx, al
        mov  bx, (program_end-$$+100h+15)/16
        mov  ah, 4ah
        int  21h
        jc   fatal

        mov  bx, 1000h
        mov  ah, 48h
        int  21h
        jc   fatal

        mov  [gen_seg], ax
        mov  [stop_api+2], ax
        mov  [play_api+2], ax
        mov  es, ax
        xor  di, di
        xor  ax, ax
        mov  cx, 8000h
        rep  stosw
        mov  dx, driver_name
        mov  di, 100h
        mov  cx, 47326
        call read_exact

        push ds
        mov  ds, [gen_seg]
        mov  si, 0b335h
        push cs
        pop  es
        mov  di, work_template
        mov  cx, 3c0h
        rep  movsb
        pop  ds

        mov  bx, 1000h
        mov  ah, 48h
        int  21h
        jc   fatal

        mov  [music_seg], ax
        mov  es, ax
        xor  di, di
        xor  ax, ax
        mov  cx, 8000h
        rep  stosw
        mov  dx, music_name
        xor  di, di
        mov  cx, 11436
        call read_exact

        mov  es, [gen_seg]
        mov  ax, [music_seg]
        mov  [es:0a04ch], ax
        mov  byte [es:0a04eh], 1
        mov  word [es:988bh], 12000
        mov byte [es:0f000h], 0e8h
        mov word [es:0f001h], 0b04ch
        mov byte [es:0f003h], 0cbh
        mov byte [es:0f004h], 0e8h
        mov word [es:0f005h], 0b147h
        mov byte [es:0f007h], 0cbh

        mov byte [es:0a099h], 0c5h
        mov byte [es:0a09eh], 0c5h
        call far [stop_api]
        cli  
        in   al, 2
        or   al, 1
        out  2, al

        mov  dx, command
        mov  ax, 257fh
        int  21h

        mov  dx, 7e8h
        mov  al, 81h
        out  dx, al
        sti  
idle:
        mov dx, 7e1h
        out dx, al
        jmp idle

read_exact:
        push cs
        pop  ds
        mov  [expected], cx
        mov  ax, 3d00h
        int  21h
        jc   fatal
        mov  bx, ax
        push ds
        mov  ax, es
        mov  ds, ax
        mov  dx, di
        inc  cx
        mov  ah, 3fh
        int  21h
        pop  ds
        jc   fatal

        cmp  ax, [expected]
        jne  fatal

        mov  ah, 3eh
        int  21h
        jc   fatal

        ret  

command:
        pusha 
        push  ds
        push  es
        cld   
        mov   dx, 7e8h
        mov   al, 80h
        out   dx, al
        in    al, 2
        or    al, 1
        out   2, al
        call  far [cs:stop_api]
        cli   
        mov   dx, 7e0h
        in    al, dx
        test  al, al
        jnz   .done

        mov   dx, 7e2h
        in    ax, dx
        cmp   ax, 50
        jae   .done

        mov   es, [cs:gen_seg]
        mov   [es:35dh], al
; Original start leaves some effect/envelope work from the previous piece.
; Restore all 12 original part templates before native initialization.
        push cs
        pop  ds
        mov  si, work_template
        mov  di, 0b335h
        mov  cx, 3c0h
        rep  movsb
        call far [cs:play_api]

        ; Timer 100Hz
        mov es, [cs:gen_seg]
        mov bx, 0a377h
        mov cx, 1
        mov ah, 2
        int 1ch

.done:
        mov  dx, 7e8h
        mov  al, 81h
        out  dx, al
        pop  es
        pop  ds
        popa 
        iret 

fatal:
        cli 
        mov dx, 7e1h
        out dx, al
        jmp fatal

gen_seg:
        dw 0
music_seg:
        dw 0
expected:
        dw 0
stop_api:
        dw 0f000h,0
play_api:
        dw 0f004h,0
driver_name:
        db 'BIOS6Z.COM',0
music_name:
        db 'GM.SMD',0
work_template:
        times 3c0h db 0
        times 8192 db 0

stack_top:
program_end:

