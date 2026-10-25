; PC-9801 Manhattan Requiem / Kiss of Murder for pc98vx driver
; (C) RuRuRu
; 2026/9/22 1st Release

; KISS=0 for Manhattan Requiem, KISS=1 for Kiss of Murder.

BITS 16
CPU 186

        ORG 0
start:
        cli  
        cld  
        xor  ax, ax
        mov  ss, ax
        mov  sp, 1000h
        mov  ds, ax

        mov  dx, 7e8h
        mov  al, 80h
        out  dx, al

        mov  word [7fh*4], command
        mov  [7fh*4+2], cs

        call sound_mute

        mov  dx, 7e8h
        mov  al, 81h
        out  dx, al
        sti  

idle:
        mov ax, 9801h
        int 18h
        jmp idle

command:
        pusha 
        push  ds
        push  es
        xor   ax, ax
        mov   ds, ax

        mov   dx, 7e0h
        in    al, dx
        cmp   al, 0
        je    select

        cmp   al, 1
        je    loaded

        cmp   al, 2
        je    stop

done:
        pop  es
        pop  ds
        popa 
        iret 

select:
        mov  dx, 7e2h
        in   ax, dx
        cmp  ax, 0ff00h
        je   advance

        test ax, ax
        jz   stop

        test al, al
        jz   done

%ifdef KISS
        cmp al, 8
%else
        cmp al, 6
%endif
        ja   done

        xor  bx, bx
        mov  bl, al
        dec  bx
        cmp  ah, [cs:limits+bx]
        ja   done

        push ax
        call sound_mute
        pop  ax

        mov  [cs:phase], ah
        xor  bx, bx
        mov  bl, al
        dec  bx
        mov  ah, [cs:limits+bx]
        mov  [cs:limit], ah
        xor  ah, ah
        mov  dx, 7d2h
        out  dx, ax
        xor  ax, ax
        mov  dx, 7d4h
        out  dx, ax
        mov  ax, 3000h
        mov  dx, 7d6h
        out  dx, ax
        mov  al, 20h
        mov  dx, 7d0h
        out  dx, al
        in   al, dx
        test al, al
        jnz  done

loaded:
        mov ax, 3000h
        mov es, ax
        cmp byte [cs:limit], 0
        je  .start

        mov al, [cs:phase]
        mov [es:3], al

.start:
        call 3000h:0
        mov  byte [cs:playing], 1
        jmp  done

advance:
        cmp byte [cs:playing], 1
        jne done

        mov al, [cs:phase]
        cmp al, [cs:limit]
        jae done

        inc al
        mov [cs:phase], al
        mov bx, 3000h
        mov es, bx
        mov [es:3], al
        jmp done

stop:
        call sound_mute
        jmp  done

sound_mute:
        mov byte [cs:playing], 0

        cli 
        in  al, 0ah
        or  al, 10h
        out 0ah, al
        mov  word [14h*4], stopped_irq
        mov  [14h*4+2], cs

        mov  bx, 2730h
        call opn_write
        mov  bx, 2800h
        call opn_write
        inc  bl
        call opn_write
        inc  bl
        call opn_write
        mov  bx, 0800h
        call opn_write
        inc  bh
        call opn_write
        inc  bh
        call opn_write
        mov  bx, 07bfh
        call opn_write
        ret  

; YM2203 write
; BH: register
; BL: value
opn_write:
        mov dx, 188h
.wait:
        in   al, dx
        test al, 80h
        jnz  .wait
        mov  al, bh
        out  dx, al
.wait_data:
        in   al, dx
        test al, 80h
        jnz  .wait_data
        add  dx, 2
        mov  al, bl
        out  dx, al
        ret  

stopped_irq:
        push ax
        mov  al, 20h
        out  8, al
        out  0, al
        pop  ax
        iret 

phase:
        db 0
limit:
        db 0
playing:
        db 0
%ifdef KISS
limits:
        db 0,0,8,6,0,0,0,0
%else
limits:
        db 0,0,0,8,5,5
%endif

