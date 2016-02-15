
;*************************************************************


dcompr:     equ #20 ;compare hl et de
disscr:     equ #41 ;disable screen
enascr:     equ #44 ;enable screen
ldirmv:     equ #59 ;vram -> ram
ldirvm      equ #5c ;ram -> vram
chgmod:     equ #5f ;change graphic mode
chgclr:     equ #62 ;change colors
clrspr:     equ #69 ;clear sprites
beep:       equ #c0 ;beep!!
cls:        equ #c3 ;clear screen
gtstck:     equ #d5 ;get joystick
gttrig:     equ #d8 ;get trigger
gtpad:      equ #db ;get pad
bigfil:     equ #16b    ;fill vram
nsetrd:     equ #16e    ;new set add for read
nstwrt:     equ #171    ;new set add for write
nrdvrm:     equ #174    ;new read vram
nwrvrm:     equ #177    ;new write vram
chgcpu:     equ #180    ;change cpu mode
getcpu:     equ #183    ;get cpu mode

wrboot:     equ #0000
bdos:       equ #0005
rdslt:      equ #000c
wrslt:      equ #0014
CALSLT:     equ #001c
enaslt:     equ #0024
callf:      equ #0030
setdma:     equ     26
read:       equ     39
open:       equ     15
close:      equ     16
subrom:     equ #faf8       ;sub rom slot
hokvld:     equ #fb20
exttbl:     equ #fcc1       ;main rom slot
extbio:     equ #ffca


; ************
; ** MACROs **
; ************


    MACRO  WPSG  X,Y            ; SCRIVI NEL PSG

        LD  A,X
        OUT (#A0),A
        LD  A,Y
        OUT (#A1),A

        ENDM


; x4,x8,x16,x32: mutilpy A, HL, IX or IY times 4,8,16 or 32
; syntax:x8  reg#
; modifies:   A, HL, IX or IY
; note:      use only with A, HL, IX or IY
;

    MACRO x4  X
    ADD X,X
    ADD X,X
    ENDM

    MACRO x8  X
    ADD X,X
    x4 X
    ENDM

    MACRO x16 X
    x8  X
    ADD X,X
    ENDM

    MACRO x32 X
    x16  X
    ADD X,X
    ENDM


; vdp: send value in A to VDP register
; syntax:vdp reg#
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
; (6 bytes/31 cycles)
;
     MACRO  vdp  reg
        out (vdpport1),a
        ld  a,reg or 010000000b
        out (vdpport1),a
        endm


; scr5: set srceen 5
; syntax:scr5
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
; 
;
     MACRO  scr5
        ld  a,6
        ld  (vdpregs0),a
        vdp 0
        ld  a,98
        ld  (vdpregs0+1),a
        vdp 1
        ld  a,31
        ld  (vdpregs0+2),a
        vdp 2
        ld  a,8
        ld  (vdpregs1),a
        vdp 8
        ld  a,130
        ld  (vdpregs1+1),a
        vdp 9
        ld  a,0
        ld  (vdpregs1+3),a
        vdp 11

        endm


; rdvdp: read VDP status register
; syntax:rdvdp    reg#
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
; (13 bytes/62 cycles)
;
        MACRO rdvdp reg
        ld  a,reg
        ld  (vdpregs1+15),a
        vdp 15      ; set VDP status register to read
        in  a,(vdpport1)
        endm


; selvram: select VRAM access from VDP (instead of expanded RAM)
; syntax:selvram
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
;
        MACRO selvram  
        ld  a,(vdpregs1+45)
        and 010111111b
        ld  (vdpregs1+45),a
        vdp 45
        endm




; r2v8: copy RAM block to VRAM (up to 256 bytes) (low 64Kb)
; syntax:r2v8<RAM addr>, <VRAM addr>, <number of bytes>
; modifies:   AF,HL,BC,DE
; note:      **** INTERRUPTS MUST BE DISABLED ****
; (15 bytes/151+21*num cycles)
;
    MACRO r2v8       ram,vram,num
        ld  de,vram         ; 3/10
        call    setvramaddr_w     ; 3/(17+104)
        ld  hl,ram          ; 3/10
        ld  c,vdpport0    ; 3/10
        rept    num
        OUTI
        endm


; r2v16: copy RAM block to VRAM (up to 65535 bytes) (low 64Kb)
; syntax:r2v16    <RAM addr>, <VRAM addr>, <number of bytes>
; modifies:   AF,HL,DE,C
; note:      **** INTERRUPTS MUST BE DISABLED ****
; (25 bytes/158+(49*num) cycles)
;
        MACRO r2v16   ram,vram,num
        ld  de,vram         ; 3/10   15/158
        call setvramaddr_w     ; 3/(17+104)
        ld  de,num          ; 3/10
        ld  hl,ram          ; 3/10
        ld  c,vdpport0        ; 2/7
        ; jp jumps here
        ; this loop repeated for each byte sent to VRAM
        ld  a,(hl)           ; 1/7    10/49
        out (c),a            ; 2/12
        inc hl          ; 1/6
        dec de          ; 1/6
        ld  a,d         ; 1/4
        or  e           ; 1/4
        ; JP used for speed instead
        ; of JP (10 vs 12 cycles)
        jp  nz,$-7           ; 3/10
        endm

; r2v16e: copy RAM block to VRAM (up to 65535 bytes) (full 128Kb)
; input Cy = A16
; syntax:r2v16e    <RAM addr>, <VRAM addr>, <number of bytes>
; modifies:   AF,HL,DE,C
; note:      **** INTERRUPTS MUST BE DISABLED ****
; (25 bytes/158+(49*num) cycles)
;
       MACRO r2v16e    ram,vram,num
        ld  de,vram         ; 3/10   15/158
        call setvramaddr2_w     ; 3/(17+104)
        ld  de,num          ; 3/10
        ld  hl,ram          ; 3/10
        ld  c,vdpport0        ; 2/7
        ; jp jumps here
        ; this loop repeated for each byte sent to VRAM
        ld  a,(hl)           ; 1/7    10/49
        out (c),a            ; 2/12
        inc hl          ; 1/6
        dec de          ; 1/6
        ld  a,d         ; 1/4
        or  e           ; 1/4
        ; JP used for speed instead
        ; of JP (10 vs 12 cycles)
        jp  nz,$-7           ; 3/10
        endm


; set192lines: set 192 lines VDP display mode
; syntax:set192lines
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
; (14 bytes/64 cycles)
;
    MACRO   set192lines   
        ld  a,(vdpregs1+9)    ; 3/13
        and 001111111b        ; 2/7
        ld  (vdpregs1+9),a    ; 3/13
        vdp 9           ; 6/31
        endm


; set212lines: set 212 lines VDP display mode
; syntax:set212lines
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
; (14 bytes/64 cycles)
;
    MACRO   set212lines   
        ld  a,(vdpregs1+9)    ; 3/13
        or  010000000b        ; 2/7
        ld  (vdpregs1+9),a    ; 3/13
        vdp 9           ; 6/31
        endm


; spriteson: turn ON V99x8 sprites display
; syntax:spriteson
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
;
    MACRO   spriteson     
        ld  a,(vdpregs1+8)
        and 011111101b
        ld  (vdpregs1+8),a
        vdp 8
        endm


; spritesoff: turn OFF V99x8 sprites display
; syntax:spritesoff
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
;
    MACRO   spritesoff    
        ld  a,(vdpregs1+8)
        or  000000010b
        ld  (vdpregs1+8),a
        vdp 8
        endm


; setintline: set line number for vertical scanning interrupt
; syntax:setintline    line#
; modifies:   AF,HL
; note:      **** INTERRUPTS MUST BE DISABLED ****
; note:      The status if VDP register #23 is read and the interrupt
;       line is set accordingly, so the interrupt line specifies
;       the interrupt line ON THE PHYSICAL SCREEN, not on the
;       VDP space.
; (15 bytes/68 bytes)
;
    MACRO setintline       line
        ld  hl,vdpregs1+23    ; 3/10
        ld  a,line          ; 2/7
        add a,(hl)           ; 1/7
        ld  (vdpregs1+19),a        ; 3/13
        vdp 19          ; 6/31
        endm


; vblankon: turn ON vblank interrupts
; syntax:vblankon
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
;
    MACRO   vblankon 
        ld  a,(vdpregs0+1)
        or  000100000b
        ld  (vdpregs0+1),a
        vdp 1
        endm


; vblankoff: turn OFF vblank interrupts
; syntax:vblankoff
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
;
    MACRO   vblankoff   
        ld  a,(vdpregs0+1)
        and 011011111b
        ld  (vdpregs0+1),a
        vdp 1
        endm


; lineinton: turn ON line interrupts
; syntax:lineinton
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
;
    MACRO   lineinton   
        ld  a,(vdpregs0+0)
        or  000010000b
        ld  (vdpregs0+0),a
        vdp 0
        endm


; lineintoff: turn OFF line interrupts
; syntax:lineintoff
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
;
    MACRO   lineintoff  
        ld  a,(vdpregs0+0)
        and 011101111b
        ld  (vdpregs0+0),a
        vdp 0
        endm


; checkkbd: ckeck keyboard line
; syntax:checkkbd <keyboar line #>
; modifies:   AF
; (8 bytes/41 cycles)
;
    MACRO checkkbd    kbdline
        in  a,(i8255portc)
        and 011110000b    ; upper 4 bits contain info topreserve
        or  kbdline
        out (i8255portc),a
        in  a,(i8255portb)
        endm


; fillvram: fill VRAM with a value
; syntax:fillvram <address>,<number of bytes>,<value>
; modifies:   AF,BC,DE
; note:      **** INTERRUPTS MUST BE DISABLED ****
;
    MACRO fillvram    address,count,value
        ld  de,address
        callsetvramaddr_w
        ld  de,count
        ld  bc,value*256 + vdpport0
        out (c),b            ; jp jumps here
        dec de
        ld  a,d
        or  e
        jp  nz,$-5
        endm


; sprsize16: set sprites size to 16x16 pixels
; syntax:sprsize16
; modifies:   AF
; note:      **** INTERRUPTS MUST BE DISABLED ****
;
        MACRO   sprsize16       
        ld  a,(vdpregs0+1)
        or  000000010b
        ld  (vdpregs0+1),a
        vdp 1
        endm


; pushstd: push standard set of registers (not alternate)
; syntax:pushstd
; modifies:   SP
; note:      alternate registers are not PUSHed
; (4 bytes/44 cycles)
;
      MACRO pushstd
        push hl          ; 1/11
        push bc          ; 1/11
        push de          ; 1/11
        push af          ; 1/11
        endm


; popstd: pop standard set of registers (not alternate)
; syntax:popstd
; modifies:   SP
; note:      alternate registers are not POPed
; (4 bytes/40 cycles)
;
    MACRO   popstd   
        pop af          ; 1/10
        pop de          ; 1/10
        pop bc          ; 1/10
        pop hl          ; 1/10
        endm


; ax32: multiply A times 32, leave result in HL
; syntax:ax32
; modifies:   AF,HL,DE
; (16 bytes/62 cycles)
;
    MACRO   ax32    
        ld  e,a         ; 1/4
        ; high part
        and 011111000b        ; 2/7    6/23
        rrca            ; 1/4
        rrca            ; 1/4
        rrca            ; 1/4
        ld  h,a         ; 1/4
        ; low part
        ld  a,e         ; 1/4    9/35
        and 000000111b        ; 2/7
        rlca            ; 1/4
        rlca            ; 1/4
        rlca            ; 1/4
        rlca            ; 1/4
        rlca            ; 1/4
        ld  l,a         ; 1/4
        endm


; adiv32: divide A by 32, leave result in A and b3 in carry
; syntax:hldiv8
; modifies:   AF
; ()
;
    MACRO   adiv32  
        rrca
        rrca
        rrca
        rrca
        rrca
        ENDM

; Cx: multiply C by VAL>0, leave result in A
; syntax:Cx VAL
; modifies:   AF,B
; ()
;
    MACRO Cx  VAL   

        ld  b,VAL
        xor a
.VA_YM
        add a,c
        djnz .VA_YM
        
        ENDM

;      enter:  A=8 bit number
;              DE=16 bit number
;       exit:  HL=A*DE, least significant 16 bits

    MACRO AxDE       VAL
            LD HL,0       ;  10
            LD B,8        ;  7
.LOOP_YM:   ADD HL,HL     ;  11
            RLA           ;  4
            JR NC,.NOADD_YM  ;  12/7      if 0: 12, 1: 18
            ADD HL,DE     ;  11         avg of 15
.NOADD_YM:  DJNZ .LOOP_YM ;  13/8
            ENDM
    

; hldiv8: divide HL by 8, leave result in HL
; syntax:hldiv8
; modifies:   AF,HL,DE
; ()
;
    MACRO   hldiv8   
        ; high part
        ld  a,h
        and 011111000b
        rrca
        rrca
        rrca
        ; high part stored in D
        ld  d,a
        ; middle part
        ld  a,h
        and 000000111b
        rrca
        rrca
        rrca
        ;temp value stored in E
        ld  e,a
        ; lower part
        ld  a,l
        and 011111000b
        rrca
        rrca
        rrca
        or  e
        ld  h,d
        ld  l,a
        ENDM


; hlx128: multiply HL times 128, leave result in HL
; syntax:hlx128
; modifies:   AF,DE,HL
; (32 bytes/105 cycles)
;
        MACRO   hlx128   
        ; lower part
        ld  a,l
        and 000000001b
        rrca
        ; lower value in E
        ld  e,a
        ; middle part
        ld  a,l
        and 011111110b
        rrca
        ; lower value in l
        ld  l,e
        ld  e,a
        ld  a,h
        and 000000001b
        rrca
        or  e
        ld  h,a
        endm

;*************************************************************
; set VRAM address for read/write (low 16Kb)
; input: hl = VRAM address (bits A0-A13)
; modifies:   AF
; note:      **** INTERRUPTS MUST BE DISABLED ****
        MACRO   vrmaddr_w
        ld  a,l         ; 1/4
        ; bits A7-A0 (low 16Kb)
        out (vdpport1),a      ; 2/11

        ld  a,h         ; 1/4    5/18
        and 000111111b        ; 2/7
        or  001000000b        ; 2/7
        ; bits A13-A8, bit 6=1 (w)
        out (vdpport1),a      ; 2/11
        ENDM

; set VRAM address for read/write (low 64Kb)
; input: DE = VRAM address (bits A0-A15)
; modifies:   AF
; note:      **** INTERRUPTS MUST BE DISABLED ****
; (22 bytes/104 cycles)
;
setvramaddr_w:
        ld  a,d         ; 1/4    5/19
        rlca            ; 1/4
        rlca            ; 1/4
        and 000000011b        ; 2/7
        ; bits A16-A14
        vdp 14          ; 6/31

        ld  a,e         ; 1/4
        ; bits A7-A0 (low 16Kb)
        out (vdpport1),a      ; 2/11

        ld  a,d         ; 1/4    5/18
        and 000111111b        ; 2/7
        or  001000000b        ; 2/7
        ; bits A13-A8, bit 6=1 (w)
        out (vdpport1),a      ; 2/11

        ret             ; 1/10

; set VRAM address for read/write (128Kb)
; input: Cy & DE = VRAM address (DE = bits A0-A15, Cy = A16)
; modifies:   AF
; note:      **** INTERRUPTS MUST BE DISABLED ****
; (22 bytes/104 cycles)
;
setvramaddr2_w:
        ld a,d 
        rla 
        rla 
        rla 
        and 000000111b        ; 2/7
        ; bits A16-A14
        vdp 14          ; 6/31

        ld  a,e         ; 1/4
        ; bits A7-A0 (low 16Kb)
        out (vdpport1),a      ; 2/11
        
        ld  a,d         ; 1/4    5/18
        and 000111111b        ; 2/7
        or  001000000b        ; 2/7
        ; bits A13-A8, bit 6=1 (w)        
        out (vdpport1),a      ; 2/11
        ret
        
; wait_hbl: Wait for a complete line
; syntax:wait_hbl
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
; note:      **** SET S#2 BEFORE CALLING !!!  ****
;        
    MACRO   wait_hbl 
.VA_YM
        in a,(#99)
        and %00100000
        jp nz,.VA_YM
.VB_YM
        in a,(#99)
        and %00100000
        jp z,.VB_YM
        ENDM


; wait_vbl: Wait till VDP start plotting vertical border
; syntax:wait_vbl
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
; note:      **** SET S#2 BEFORE CALLING !!!  ****
;        
    MACRO   wait_vbl 
.VA_YM  call setclrxyshp
        in a,(#99)
        and %01000000
        jp z,.VA_YM
        ENDM

     MACRO  wait_vbl_n
.VA_YM
        in a,(#99)
        and %01000000
        jp nz,.VA_YM
        ENDM


; wait_rdy: Wait for VDP to complete its command
; syntax:wait_rdy
; modifies:   A
; note:      **** INTERRUPTS MUST BE DISABLED ****
; note:      **** SET S#2 BEFORE CALLING !!!  ****
;        
    MACRO   wait_rdy 
        IF  DEBUG1
                ld  a,(CLRPRF)
                ld  l,a
                vdp 7
                inc l
                ld  a,l
                ld  (CLRPRF),a
        ENDIF

.VA_YM  IN  A,(#99)
        RRCA
        JP  C,.VA_YM

        IF  DEBUG1
                xor a
                vdp 7
        ENDIF

        ENDM

; vdp_cmd: send to VDP a command sequence pointed by HL 
; syntax:vdp_cmd
; modifies:   A,HL,BC
; note:      **** INTERRUPTS MUST BE DISABLED ****
;        
    MACRO vdp_cmd  LIST,NLIST
        ld  hl,LIST
        LD  A,32+(15-NLIST)
        vdp 17
        LD  C,vdpport3
        ASSERT (NLIST =11) || (NLIST =15)
        IF NLIST=11
            call    out11
        ELSE 
            call    out15
        ENDIF
        ENDM


    MACRO calslt    SLOTADD,ADD   ;inter slot call macro
        ld  iy,(SLOTADD-1)
        ld  ix,ADD
        call    CALSLT
        ENDM

    macro outvdp  value,reg
    ld a,value
    vdp reg
    endm

out15
        rept    4
         OUTI
        endm
out11
        rept    11
         OUTI
        endm
        ret




