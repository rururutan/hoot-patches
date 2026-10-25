; PC-9801 Xanadu
; (C) RuRuRu
; 2026/09/22 1st Release

BITS 16
CPU 186

; Adjust tempo
DELAY_PASSES equ 2

        ORG  0
start:
        cli 
        cld 
        mov ax, 6000h
        mov ss, ax
        mov sp, 0fffeh
        xor ax, ax
        mov ds, ax
        mov word [7fh*4], command
        mov [7fh*4+2], cs
        mov al, 7
        out 37h, al
        mov dx, 7e8h
        mov al, 81h
        out dx, al
        sti 

checkpoint:
        push cs
        pop  ds
        cmp  word [pending], 0ffffh
        je   .ready

        cli  
        mov  ax, [pending]
        mov  word [pending], 0ffffh
        sti  
        call select
.ready:
        cmp  word [active+2], 0
        je   checkpoint

        mov  ax, [active+2]
        mov  ds, ax
        call far [cs:active]
        jmp  checkpoint

command:
        push ax
        push dx
        mov  dx, 7e0h
        in   al, dx
        cmp  al, 2
        je   .stop
        test al, al
        jnz  .done
        mov  dx, 7e2h
        in   ax, dx
        cmp  ax, 12h
        je   .queue
        cmp  ax, 4
        ja   .done
        jmp  .queue

.stop:
        xor ax, ax

.queue:
        mov [cs:pending], ax

.done:
        pop  dx
        pop  ax
        iret 

select:
        mov  [request], ax
        mov  word [active+2], 0
        push ax
        mov  al, 7
        out  37h, al
        pop  ax
        test ax, ax
        jz   .done

        cmp  ax, 12h
        jne  .normal

        mov  ax, 2
.normal:
        dec ax
        mov bx, 10
        mul bx
        mov si, ax
        xor dx, dx
        cmp word [request], 12h
        jne .food

        inc dx

.food:
        mov  ax, [table+si]
        mov  es, ax
        mov  [active+2], ax
        mov  byte [es:606ah], 0
        mov  byte [es:617ah], 9
        mov  byte [es:6178h], 7
        mov  byte [es:607eh], 0
        mov  byte [es:6170h], 0
        mov  word [es:60a5h], 1
        mov  byte [es:60a7h], 0
        test dx, dx
        jz   .init

        mov  word [es:60a5h], 0
.init:
        mov bx, [table+si+6]
        mov word [es:bx], 1
        mov ax, [table+si+8]
        mov [es:bx+2], ax
        mov [es:bx+4], ax
        mov byte [es:0f000h], 0e8h
        mov ax, [table+si+2]
        sub ax, 0f003h
        mov [es:0f001h], ax
        mov byte [es:0f003h], 0e8h
        mov ax, [table+si+4]
        sub ax, 0f006h
        mov [es:0f004h], ax

        mov di, 0f006h
        mov cx, DELAY_PASSES-1
.delay:
        mov  byte [es:di], 0e8h
        mov  ax, [table+si+4]
        sub  ax, di
        sub  ax, 3
        mov  [es:di+1], ax
        add  di, 3
        loop .delay

        mov  byte [es:di], 0cbh
.done:
        ret 

pending:
        dw 0ffffh
request:
        dw 0
active:
        dw 0f000h,0

; Segment, tick, delay, state, song.
table:
        dw 1000h,1a68h,04d3h,1b16h,1c06h
        dw 2000h,42d8h,0d12h,43a4h,4494h
        dw 3000h,15c8h,052ah,1676h,1766h
        dw 4000h,15f8h,04dfh,16a6h,1796h

