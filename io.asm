
;------------------------------------------
; Olivier Hustin's diskload
;------------------------------------------

clrfcb: ld  hl,fcb
        ld  b,37
        xor a
clrfcb0:
        ld  (hl),a
        inc hl
        djnz    clrfcb0
        ret
setfcb:
        push hl
        ld hl,fcb+0
        ld de,fcb+1
        ld bc,36
        ld (hl),b
        ldir
        pop hl
        ld de,fcb
        ld bc,12
        ldir
        ret

diskload:
        push de
        call setfcb
        call openf
        ld hl,(bleng)
        pop de
        push af
        call loadf
        call closef
        pop af
        ret
openf:  ld      de,fcb
        ld      c,open
        call    bdos
        ld      hl,1
        ld      (groot),hl
        dec     hl
        ld      (blok),hl
        ld      (blok+2),hl
        ret
loadf:  push    hl
        ld      c,setdma
        call    bdos
        ld      de,fcb
        pop     hl
        ld      c,read
        call    bdos
        or a
        ret
closef: ld      de,fcb
        ld      c,close
        jp      bdos

stopdsk:
        ld ix,#401f
        ld iy,(#fb21)
        call #1c
        ret

fcb:    defb    0
        defb    "???????????"
        defw    0
groot:  defw    0
bleng:  defw    0
        defb    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
blok:   defw    0
        defw    0
        ds 10


