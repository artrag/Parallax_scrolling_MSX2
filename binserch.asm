    OUTPUT for2.com

   ORG 100h

BDOS    equ 00005H
STROUT  equ 00009H


start   
autoexec
                struct    SPRT
p_Y             db        Y
p_X             dw        X
p_DX            db        DX
p_DY            db        DY
p_attribute1    dw        attribute1
p_attribute2    dw        attribute2
                ens    

p_record_SPRT0  SPRT
p_record_SPRT1  SPRT
p_record_SPRT2  SPRT
p_record_SPRT3  SPRT
p_record_SPRT4  SPRT
p_record_SPRT31 SPRT

Array_SPRT_pointers:

                dw  p_record_SPRT0
                dw  p_record_SPRT1
                dw  p_record_SPRT2
                dw  p_record_SPRT3
                dw  p_record_SPRT4
                dw  p_record_SPRT31
                
start:

       ld     hl, array_SPRT_pointers
       ld     de, array_SPRT_pointers + 32*2

loop:
       push     hl        ;       p_head
       push     de        ;       p_tail

       sll     hl
       sll     de
       add   hl,de        ;       hl = p_mid
       push  hl           ;       p_mid

       ld     bc,(hl)     ;       bc = *p_mid
       ld     hl,SPRT.p_Y
       add  hl,bc         ;       hl = *p_mid + SPRT.p_Y
       ld    a,(hl)       ;       a = *(*p_mid + SPRT.p_Y)
       cp    YC
       jr    nc,elseif
  
       pop    de         ;        p_tail  = p_mid
       pop    af         ;        drop previous p_tail
       pop    hl         ;        p_head

       jr    loop

elseif:

       ld     bc, SPRT.p_DY-SPRT.p_Y
       add   hl,bc      ;         hl = *p_mid + SPRT.p_DY
       add   a,(hl)     ;         a = *(*p_mid + SPRT.p_Y) + *(*p_mid + SPRT.p_DY)
       ld    b,a
       ld    a,YC
       cp    b
       jr    nc,else

       pop    hl         ;         p_head  = p_mid
       pop    de         ;         p_tail
       pop    af         ;         drop previous p_head

       jr    loop

else:

       pop       af      ;        drop previous p_mid
       pop       de      ;        p_tail
       pop       hl      ;        p_haed

finish
;
      END


