; SYNUPS DOS/V player for hoot (version 2026/12/31 later)
; (C) RuRuRu
; 2026/08/02 1st Release
;

%include 'hoot.inc'

int_hoot       equ 0x7f
int_synups     equ 0xd2
int_synplay    equ 0xd3
buffer_paras   equ 0x0800          ; 32 KiB for file and relocated SIB
stack_size     equ 1024            ; same size as the PC-98 reference player
pit_divisor    equ 0x0792          ; value programmed by G4XOPEN

                org     0x0100
                use16
                cpu     186

start:
                cli
                mov     ax, cs
                mov     ds, ax
                mov     es, ax

                mov     dx, HOOTFUNC
                mov     al, HF_DISABLE
                out     dx, al

                mov     ss, ax
                mov     sp, stack

                ; Release the COM image's unused allocation.
                mov     bx, prgend
                add     bx, 0x0f
                shr     bx, 4
                mov     ah, 0x4a
                int     0x21
                jc      fatal

                ; Source file buffer.
                mov     bx, buffer_paras
                mov     ah, 0x48
                int     0x21
                jc      fatal
                mov     [file_seg], ax

                ; Relocated score information block.
                mov     bx, buffer_paras
                mov     ah, 0x48
                int     0x21
                jc      fatal
                mov     [score_seg], ax

                ; One-time SYNPLAY setup performed by G4XOPEN.EXE.
                mov     ah, 0x01
                int     int_synplay
                mov     ah, 0x14
                mov     ch, 0x14
                mov     cl, 0x19
                int     int_synplay

                mov     ah, 0x11
                int     int_synups
                mov     [synups_tick], ax
                mov     [synups_tick+2], cx
                mov     ah, 0x17
                int     int_synups
                mov     [synplay_tick], ax
                mov     [synplay_tick+2], cx

                mov     ax, 0x3508
                int     0x21
                mov     [old_int8], bx
                mov     [old_int8+2], es
                mov     ax, cs
                mov     ds, ax
                mov     dx, vect_timer
                mov     ax, 0x2508
                int     0x21

                cli
                mov     al, 0x36
                out     0x43, al
                mov     ax, pit_divisor
                out     0x40, al
                mov     al, ah
                out     0x40, al
                sti

                mov     ah, 0x25
                mov     al, int_hoot
                mov     dx, vect_hoot
                int     0x21

                mov     dx, HOOTFUNC
                mov     al, HF_ENABLE
                out     dx, al
                sti

mainloop:
                hlt
                cmp     byte [start_pending], 1
                jne     mainloop

                mov     ah, 0x0f
                int     int_synplay
                or      ax, ax
                jnz     mainloop

                mov     byte [start_pending], 0
                mov     ah, 0x03
                int     int_synplay
                jmp mainloop

fatal:
                sti
                hlt
                jmp     short fatal

vect_timer:
                pusha
                push    ds
                push    es
                mov     ax, cs
                mov     ds, ax

                cmp     byte [timer_seen], 0
                jne     short .synups_count
                mov     byte [timer_seen], 1

.synups_count:
                inc     byte [synups_count]
                cmp     byte [synups_count], 3
                jb      short .synplay_count
                mov     byte [synups_count], 0
                call    far [cs:synups_tick]

.synplay_count:
                inc     byte [synplay_count]
                cmp     byte [synplay_count], 6
                jb      short .eoi
                mov     byte [synplay_count], 0
                call    far [cs:synplay_tick]

.eoi:
                inc     byte [bios_count]
                cmp     byte [bios_count], 0x22
                jb      short .send_eoi
                mov     byte [bios_count], 0
                pushf
                call    far [cs:old_int8]
                jmp     short .restore

.send_eoi:
                mov     al, 0x20
                out     0x20, al
.restore:
                pop     es
                pop     ds
                popa
                iret

vect_hoot:
                pusha
                push    ds
                push    es
                mov     ax, cs
                mov     ds, ax
                mov     es, ax
                mov     dx, HOOTPORT
                in      al, dx
                cmp     al, HP_PLAY
                je      .play
                cmp     al, HP_STOP
                je      .stop
                jmp     .done

.play:
                mov     ds, [file_seg]
                xor     dx, dx
                mov     cx, buffer_paras * 16
                xor     bx, bx
                mov     ah, 0x3f
                int     0x21
                jc      .stop
                cmp     ax, 15             ; minimum SYNUPS1 container
                jb      .stop
                mov     cs:[file_size], ax

                mov     ax, cs
                mov     ds, ax
                call    relocate_sib
                jc      .done

                ; Stop/reset the previous score before loading a new one.
                mov     ah, 0x01
                int     int_synplay
                mov     es, cs:[score_seg]
                xor     bx, bx
                mov     ax, 0x0001
                int     int_synplay
                or      ax, ax
                jnz     short .done
                mov     byte cs:[start_pending], 1
                jmp     short .done

.stop:
                mov     byte cs:[start_pending], 0
                mov     ah, 0x01
                int     int_synplay

.done:
                pop     es
                pop     ds
                popa
                iret

relocate_sib:
                push    ds
                push    si
                push    di
                push    bx
                push    cx
                push    dx

                mov     ds, [file_seg]
                xor     si, si
                mov     ax, cs
                mov     es, ax
                mov     di, synups1_id
                mov     cx, synups1_id_len
                repe cmpsb
                jne     .error

                mov     cx, [9]
                cmp     cx, buffer_paras * 16
                ja      .error
                mov     ax, cx
                add     ax, 13              ; header + relocation-count word
                cmp     ax, cs:[file_size]
                ja      .error

                mov     si, 11
                mov     es, cs:[score_seg]
                xor     di, di
                push    cx
                rep movsb
                pop     ax                  ; SIB size

                ; SI now points at the relocation count.
                lodsw
                mov     cx, ax
                mov     ax, cx
                shl     ax, 1
                shl     ax, 1
                add     ax, si
                cmp     ax, cs:[file_size]
                ja      .error

.reloc_loop:
                jcxz    .success
                lodsw                       ; pointer field offset
                mov     di, ax
                lodsw                       ; pointer target offset
                mov     es:[di], ax
                mov     ax, cs:[score_seg]
                mov     es:[di+2], ax
                loop    .reloc_loop

.success:
                clc
                jmp     short .done
.error:
                stc
.done:
                pop     dx
                pop     cx
                pop     bx
                pop     di
                pop     si
                pop     ds
                ret

synups1_id:    db      'SYNUPS1', 0
synups1_id_len equ     $ - synups1_id

file_seg:       dw      0
score_seg:      dw      0
file_size:      dw      0
start_pending:  db      0
timer_seen:     db      0
synups_count:   db      0
synplay_count:  db      0
bios_count:     db      0
                align   2
synups_tick:    dw      0, 0
synplay_tick:   dw      0, 0
old_int8:       dw      0, 0

                align   16
                times   stack_size db 0xff
stack:
prgend:
