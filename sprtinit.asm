; Riempe le 128 forme degli sprite con i modelli dei caratteri (meglio di niente per ora)

        scf
        r2v16e (#F920),128*(16*VSCSZ+256),8*256
        scf
        r2v16e (#F920),128*(16*VSCSZ+256+16),8*256
        scf
        r2v16e (#F920),128*(16*VSCSZ+256+32),8*256
        scf
        r2v16e (#F920),128*(16*VSCSZ+256+64),8*256
        ; #1bbf

        ld  de,7800h
        call    setvramaddr_w

        ld  bc,64*32
rn5     ld  a,#FF
        out (vdpport0),A
        dec bc
        ld  a,b
        or  c
        jp  nz,rn5


; Riempe i XXX colori degli sprite con i colori 8,4 e 12

        ld  b,127
        ld  hl,SPRTCOL

rn4     push bc

        ld  b,16
rn4a    ld  a,r
        and #0F
        ld  (hl),a
        inc hl
        djnz rn4a

;        ld  b,16
;rn4b    ld  a,r
;        and #0F
;        or  64
;        ld  (hl),a
;        inc hl
;        djnz rn4b

        pop bc
        djnz rn4

;         ld  e,l
;         ld  d,h
;         ld  hl,SPRTCOL
;
;         ld  b,32
; rn8     push bc
;         ld  b,32
; rn9     ld  a,(hl)
;         or  128
;         ld  (de),a
;         inc hl
;         inc de
;         djnz rn9
;         pop bc
;         djnz rn8

; Riempe 32 attributi degli sprite con colori posizioni e forme

       ld  ix,SPTATR
       ld  bc,32*256
rn6
       ld  a,c
       x4   a
       ld  (ix+2),a        ; forme

       ld  a,c
       and #F8
       x4   a
       add  a,32
       ld  (ix+0),a        ; Y

       ld  a,c
;       cp 10                ;ZZZZZZ
;       jp   c,rn7
;       and  #FE
rn7    x16 a
       and 127
       add  a,64
       ld  (ix+1),a        ; X

       inc c
       ld   de,4
       add  ix,de
       djnz    rn6
