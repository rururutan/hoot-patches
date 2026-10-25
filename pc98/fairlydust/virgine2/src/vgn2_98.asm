; PC-9801 Virgin2 VGN2.EXE(CRC32:0x768a8cd4)演奏
; (C) RuRuRu
; 2026/10/10 1st Release

BITS 16
CPU 186

HOOTPORT equ 7e0h
HOOTFUNC equ 7e8h

        ORG 100h
start:
        cli 
        cld 
        mov ax, cs
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov sp, stack_top
        mov dx, HOOTFUNC
        mov al, 80h
        out dx, al
        mov bx, ((program_end-$$+100h)+15)/16
        mov ah, 4ah
        int 21h
        jc  fatal

        mov bx, 2400h
        mov ah, 48h
        int 21h
        jc  fatal

        mov [image_seg], ax
        mov [overlay], ax
        mov [overlay+2], ax
        mov dx, 2
.clear:
        mov  es, ax
        push ax
        xor  ax, ax
        xor  di, di
        mov  cx, 8000h
        rep  stosw
        pop  ax
        add  ax, 1000h
        dec  dx
        jnz  .clear
        mov  es, ax
        xor  ax, ax
        xor  di, di
        mov  cx, 2000h
        rep  stosw
        push cs
        pop  es
        mov  dx, exe_name
        mov  bx, overlay
        mov  ax, 4b03h
        int  21h
        jc   fatal
        mov  ax, [image_seg]
        add  ax, 139eh
        mov  [game_ds], ax
        mov  dx, [image_seg]
        add  dx, 0f5dh
        mov  [init_ptr+2], dx
        mov  [play_ptr+2], dx
        mov  [stop_ptr+2], dx
        mov  dx, [image_seg]
        add  dx, 0eb0h
        mov  [keyoff_ptr+2], dx

        mov es, [image_seg]
        mov si, patch_table
        mov cx, 5
.patch:
        lodsw 
        mov   di, ax
        mov   byte [es:di], 0eah
        lodsw 
        mov   [es:di+1], ax
        mov   [es:di+3], cs
        loop  .patch
        mov   ax, 257fh
        mov   dx, command
        int   21h

        mov   ds, [cs:game_ds]
        mov  word [0a9h], 0
        mov  byte [1e05h], 0
        call far [cs:init_ptr]
        mov  byte [cs:mode], 1

        push cs
        pop  ds
        mov  dx, HOOTFUNC
        mov  al, 81h
        out  dx, al
        sti  
.idle:
        mov ax, 9801h
        int 18h
        jmp .idle

fatal:
        mov ax, 4c01h
        int 21h
        jmp fatal

command:
        pusha 
        push  ds
        push  es
        cld   
        sti   
        mov   ds, [cs:game_ds]
        mov   dx, HOOTPORT
        in    al, dx
        cmp   al, 2
        je    .stop

        test  al, al
        jnz   .done

        call  stop_sound

        mov   dx, HOOTPORT+4
        in    al, dx
        cmp   al, 2
        je    .fm

        mov   al, 1
        jmp   .select
.fm:
        mov al, 2
.select:
        cmp al, [cs:mode]
        je  .play

        mov [cs:mode], al
        xor bx, bx
        cmp al, 2
        jne .set

        inc bx

.set:
        mov  [0a9h], bx
        call far [cs:init_ptr]

.play:
        push cs
        push word dummy_name
        call far [cs:play_ptr]
        add  sp, 4
        jmp  .done

.stop:
        call stop_sound

.done:
        pop  es
        pop  ds
        popa 
        iret 

stop_sound:
        call far [cs:stop_ptr]
        cmp  byte [cs:mode], 2
        jne  .done

        push si
        xor  si, si
.channel:
        push si
        call far [cs:keyoff_ptr]
        add  sp, 2
        inc  si
        cmp  si, 6
        jb   .channel

        pop  si
.done:
        ret

; fopen(filename,mode)
stdio_open:
        mov  ax, 1
        xor  dx, dx
        retf 

stdio_close:
        xor  ax, ax
        retf 

; fread(buffer,size,count,stream)
stdio_read:
        push bp
        mov  bp, sp
        push bx
        push cx
        push si
        push ds
        mov  ax, [ss:bp+10]
        mul  word [ss:bp+12]
        test dx, dx
        jnz  .error
        mov  cx, ax
        mov  dx, [ss:bp+6]
        mov  ds, [ss:bp+8]
        xor  bx, bx
        mov  ah, 3fh
        int  21h
        jc   .error
        xor  dx, dx
        mov  si, [ss:bp+10]
        test si, si
        jz   .error
        div  si
        jmp  .done

.error:
        xor ax, ax

.done:
        pop  ds
        pop  si
        pop  cx
        pop  bx
        pop  bp
        retf 


; farmalloc(unsigned long bytes): return paragraph-aligned DX:AX.
heap_alloc:
        push bp
        mov  bp, sp
        push bx
        push cx
        mov  ax, [ss:bp+6]
        mov  dx, [ss:bp+8]
        add  ax, 15
        adc  dx, 0
        mov  cx, 4
.shift:
        shr  dx, 1
        rcr  ax, 1
        loop .shift
        test dx, dx
        jnz  .error
        mov  bx, ax
        test bx, bx
        jz   .error
        mov  ah, 48h
        int  21h
        jc   .error
        mov  dx, ax
        xor  ax, ax
        jmp  .done
.error:
        xor ax, ax
        xor dx, dx
.done:
        pop  cx
        pop  bx
        pop  bp
        retf 

; farfree(pointer)
heap_free:
        push bp
        mov  bp, sp
        push es
        mov  ax, [ss:bp+8]
        test ax, ax
        jz   .done
        mov  es, ax
        mov  ah, 49h
        int  21h
.done:
        pop  es
        pop  bp
        retf 


patch_table:
        dw 08b7h,stdio_open
        dw 0a57h,stdio_read
        dw 0451h,stdio_close
        dw 27ebh,heap_alloc
        dw 26d3h,heap_free
image_seg:
        dw 0
game_ds:
        dw 0
overlay:
        dw 0,0
init_ptr:
        dw 3,0
stop_ptr:
        dw 3ah,0
keyoff_ptr:
        dw 0665h,0
play_ptr:
        dw 19fh,0
mode:
        db 0
exe_name:
        db 'VGN2.EXE',0
dummy_name:
        db    'INPUT.MID',0
        align 16
        times 2048 db 0
stack_top:
program_end:
