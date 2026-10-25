; PC-9801 麻雀大会
; (C) RuRuRu
; 2026/10/17 1st Release

bits 16
cpu 186

        org 8000h
start:
        cli 
        cld 
        mov dx, 7e8h
        mov al, 80h
        out dx, al

        mov ax, 107eh      ; Set Game segment
        mov ds, ax
        mov es, ax
        mov ss, ax

        mov sp, 9030h
        xor ax, ax
        mov es, ax
        mov word [es:7fh*4], command
        mov [es:7fh*4+2], cs

        mov  ax, 0a3feh
        mov  es, ax
        mov  byte [es:0eh], 8
        call 044ah         ; initialize
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
        cld   
        mov   ax, 107eh
        mov   ds, ax
        mov   es, ax
        mov   dx, 7e0h
        in    al, dx
        test  al, al
        jz    .play

        cmp   al, 2
        je    .stop

        jmp   .done

.play:
        mov dx, 7e2h
        in  ax, dx
        mov bx, songs
        mov cx, (songs_end-songs)/4
.find:
        cmp  ax, [cs:bx]
        je   .found

        add  bx, 4
        loop .find
        jmp  .stop

.found:
        push word [cs:bx+2]
        call 0527h                     ; Play (C-lang)
        add  sp, 2
        jmp  .done

.stop:
        call 060fh                     ; Stop

.done:
        pop  es
        pop  ds
        popa 
        iret 

songs:
%include "songs.inc"
songs_end:

