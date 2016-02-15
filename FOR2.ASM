    OUTPUT for2.com

   ORG 100h

BDOS    equ 00005H
STROUT  equ 00009H


start   
autoexec
        jp  inzializza
;*************************************************************

 INCLUDE macros.asm
 INCLUDE io.ASM
 INCLUDE PT3.ASM
 INCLUDE palette.asm
 
;*************************************************************
inzializza:
     ; load grfx at 4000h
        ld hl,blknm
        ld de,4000h-7
        call diskload
        jp nz,error2
        call printok2
        
        scf
        r2v16e #4000,#0000,#8000

        ; palette at #7680

        ; load grfx at 4000h
        ld hl,prlnm
        ld de,4000h-7
        call diskload
        jp nz,error3
        call printok3

        scf
        r2v16e #4000,#8000,#8000

        ; barra at #E000

        ; load grfx at 4000h
        ld hl,barnm
        ld de,4000h-7
        call diskload
        jp nz,error4
        call printok4

        r2v16 #4000,(256+192)*128,64*128

        ; load level at BASE
        ld hl,stgnm
        ld de,BASE
        call diskload
        jp nz,error1
        call printok1

        jp PARTI    
 
error1: ld  de,msgerr1
        ld  c,STROUT
        call BDOS
        ret
error2: ld  de,msgerr2
        ld  c,STROUT
        call BDOS
        ret
error3: ld  de,msgerr3
        ld  c,STROUT
        call BDOS
        ret
error4: ld  de,msgerr4
        ld  c,STROUT
        call BDOS
        ret

printok1:
        ld  de,msgok1
        ld  c,STROUT
        call BDOS
        ret
printok2:
        ld  de,msgok2
        ld  c,STROUT
        call BDOS
        ret
printok3:
        ld  de,msgok3
        ld  c,STROUT
        call BDOS
        ret
printok4:
        ld  de,msgok4
        ld  c,STROUT
        call BDOS
        ret

stgnm:      db 0,"stg3    fnd"     
msgerr1:    db "Error reading level files",13,10,"$"
msgok1:     db "Reading level files",13,10,"$"

blknm:      db 0,"blk4    sr5"     
msgerr2:    db "Error reading grfx files",13,10,"$"
msgok2:     db "Reading grfx files",13,10,"$"

prlnm:      db 0,"px      SC5"    
msgerr3:    db "Error reading parallax grfx files",13,10,"$"
msgok3:     db "Reading parallax files",13,10,"$"

barnm:      db 0,"barra   sr5"    
msgerr4:    db "Error reading infobar files",13,10,"$"
msgok4:     db "Reading infobar files",13,10,"$"



;*************************************************************

DEBUG1  EQU 0               ; mostra i wdr_rdy
DEBUG2  EQU 0               ; mostra i tempi di aggiornamento sprite
DEBUG3  EQU 0               ; mostra il tempo libero di quadro
DEBUG4  EQU 0               ; se =0 esclude l'aggiornamento delle forme sprite ram->vram
DEBUG5  EQU 0               ; se =0 esclude la musica

;*************************************************************


VDP0    EQU     #F3DF       ; Posizione in memoria del VDP0
VDP8    EQU     #F3DF+8       ; Posizione in memoria del registro di stato S#0

; RAM copy of VDP registers
; vdpregs0 -> R#0...R#7
; vdpresg1 -> R#8...R#23
;
vdpregs0    equ 0f3dfh
vdpregs1    equ 0ffe7h-8

; VDP ports
;
vdpport0    equ 098h        ; VRAM read/write
vdpport1    equ 099h        ; VDP registers read/write
vdpport2    equ 09ah        ; Palette registers write
vdpport3    equ 09bh        ; Indirect register write

; i8255 ports
;
i8255porta  equ 0a8h        ; slot selection
i8255portb  equ 0a9h        ; keyboard column input
i8255portc  equ 0aah        ; leds, motor, cassette, kbd line
i8255portd  equ 0abh        ; mode select for i8255 ports A,B,C

;*************************************************************


VSCSZ   EQU 11          ; VERTICAL SCREEN SIZE
BASE    EQU #8000
SPRTSHP EQU #1bbf

;*************************************************************

L8100       dw  BASE
NVPSWP      db  #00         ; Conta i pageswap video, serve per le animazioni dei blocchi di fondale

XDIR        DB  0           ; Direzioni orizzontali e verticali di scroll
YDIR        DB  0

scrX        dw  (BASE and #7F)*16
scrY        dw  (BASE /128) and #7F
scrX_CR     dw  0
scrY_CR     dw  0

JOY         DB  0
NPRAM       db  4           ; NUOVA PAGINA RAM
NPRAM2      db  5           ; NUOVA PAGINA RAM2

OPRAM       db  1           ; VECCHIA PAGINA RAM
OPRAM2      db  1           ; VECCHIA PAGINA RAM

KEYSTK      DB  0           ; SCEGLIE TASTIERA O JOYSTICK

TIMER       db  0           ; conta 16 frame
        
XPOS        DB  0           ; Offset dello schermo
YPOS        DB  0
XPOS_CR     DB  0
YPOS_CR     DB  0

XDIR2       DB  0           ; Direzioni orizzontali e verticali di scroll temporanee valide per 16 frame
YDIR2       DB  0

CLRPRF      db  0           ; Color profier

;*************************************************************
     
; Dati di colore su 128 sprite a 3 colori per linea (normali ed EC)

SPRTCOL      equ #B000 


;**************************************************
;            INIZIA QUI

PARTI    
        ld  a,5
        calslt  exttbl,chgmod
        
        di
        xor a
        vdp 7
        
        call SetPalet
        set192lines
        
        ld  a,2
        vdp #0f

 INCLUDE sprtinit.asm

        IF  DEBUG5 
         LD HL,SONG
         CALL INIT  ; initialize
        ENDIF


main_loop:

        IF  DEBUG1 
            ld  a,1                 ; inizializza il profiler 
            ld  (CLRPRF),a 
        ENDIF
        
        call sc_to_bar_split    ; Wait for line VSCSZ*16-2 and switch to the scorebar

        IF  DEBUG3 
            xor a
            vdp 7
        ENDIF
         
        call    calcXY          ; calculate new screen absolute position scrX,scrY
        call    nxtxy           ; calcualte new realtive screen position XPOS,YPOS

        call    intsetclrxyshp
        call bar_proc           ; Do things while the scorebar is active (page swap, plot borders)
          
        call TEST               ; Cambia direzione solo ogni 16 passi 
                                ; out XDIR2,YDIR2,TMPXPOS,TMPYPOS
        
        wait_vbl                ; Wait for vertical border
        
        spriteson

        call swap_screen        ; Display screen on new parameters 
        call plot_screen        ; Plot backgroung page
       
        call    GESTINC         ; Evaluate direction

        call    endclrxyshp
                
        call    nxtframe
      
        call testesc            ; Exit on press space key
        or a
        jp z,do_exit   

        IF  DEBUG5 
         CALL PLAY  ; play 1 quark
        ENDIF

        IF  DEBUG3 
            ld  a,15
            vdp 7
        ENDIF
        
        jp main_loop

do_exit:
        xor a
        vdp #0f

        IF  DEBUG5 
         CALL MUTE  ; silence
        ENDIF
        ei
        
        xor a
        calslt  exttbl,chgmod

        ret

    
;************************************************************
;   calculate new screen absolute position scrX,scrY
;************************************************************

calcXY

        ld  hl,(scrX)
        ld  (scrX_CR),hl
        ld  a,(XDIR2)
        ld  c,a
        ld  b,0
        bit 7,c
        jp  z,pos4
        dec b    
pos4    add hl,bc
        ld  (scrX),hl


        ld  hl,(scrY)
        ld  (scrY_CR),hl
        ld  a,(YDIR2)
        ld  c,a
        ld  b,0
        bit 7,c
        jp  z,pos5
        dec b  
pos5    add hl,bc
        ld  (scrY),hl

        ret
        
;************************************************************
; Update XPOS and YPOS accordingly to scrX, scrY, TMPXPOS,TMPYPOS
;************************************************************

offsetX db  7
offsetY db  0

nxtxy:
        LD  A,(TIMER)
        and a
        push    af
        jp nz, nopnopX
        
        ld  a,(TMPXPOS)         ; Gestione cambio bordo laterale in caso di cambio direzione
        bit 7,a
        jp  z,nopnopX
        and #0F
        ld (offsetX),a
        ld  (XPOS),a
        jp  yyy
nopnopX
        ld  a,(scrX)
        ld  l,a
        ld a,(offsetX)
        add a,l
        and #0F
        ld  (XPOS),a

yyy
        pop af
        jp nz, nopnopY

        ld  a,(TMPYPOS)         ; Gestione cambio bordo laterale in caso di cambio direzione
        bit 7,a
        jp  z,nopnopY
        and #0F
        ld (offsetY),a
        ld  (YPOS),a
        ret
        
nopnopY
        ld   a,(scrY)
        ld  l,a
        ld a,(offsetY)
        add a,l
        and #0F
        ld  (YPOS),a

        ret

;************************************************************
; Test if esc key is pressed.
; If pressed, z flag is positioned to 0 
;************************************************************
testesc:
        in a,(#aa)
        and %11110000
        add a,7
        out (#aa),a
        in a,(#a9)
        and 4
        ret

;************************************************************
; Split the screen activating the score bar in page 3.
; in: (YPOS) specifies the VDP23 line of scroll for the next frame
;************************************************************

sc_to_bar_split:

        ld a,(YPOS)
        add a,16*(VSCSZ-1)-2
        vdp 19
        
        ld  a,1
        vdp #0f
        
wtl1:
        in a,(#99)
        rrca
        jp nc,wtl1
        
        outvdp %00100010,128+1
        ld  a,%00001010
        vdp 8                   ; Sprite off
        
        ld  a,2
        vdp #0f
        wait_hbl
                
        xor a
        vdp 18
        
        ld a,64                 ; visualizza l'area più in basso dello schermo di lavoro
        vdp 23
                        
        ld  a,#3F               ; set page 1              (#7F for page 3)
        vdp 2   
        
        wait_hbl
        outvdp %01100010,128+1  
                    
        ret
;************************************************************
; Pass to next frame
;************************************************************
nxtframe:
        LD  A,(TIMER)
        INC A
        AND #0F
        LD  (TIMER),A

        ld  hl,spritbuff
        ld  b,64
fill    LD  a,(hl)
        inc a
        and 63
        ld  (hl),a    
        inc hl
        djnz    fill

        ret

;************************************************************
; Border processing while the score bar in page 3 is active.
; in: (YPOS_CR) specifies the current VDP23 line of vertical scroll
; in: (XPOS_CR) specifies the current VDP18 colummn of horizzontal scroll
; in: (YPOS) is the  next frame VDP23 value
; in: (XPOS) is the  next frame VDP18 value
;************************************************************
bar_proc:
        
;   processa ora i bordi e la posizione del prossimo frame

        LD  A,(TIMER)
        and a
        jp  NZ,noswap
swap        
        LD  A,(ACTPG)           ; Cambia la pagina di destinazione in cui il VDP lavora 
        ld  (BRDMSKDST+3),a
        ld  (BRDNEWDST+3),a
        XOR #01
        LD  (ACTPG),A
noswap
                
        ld  a,(XDIR2)
        cp  1
        jp  z,borderSX
        cp  -1
        jp  z,borderDX

        jp noborder

borderDX
        ld  a,(XPOS)
        bit 3,a
        jp  z,poss
        or  #F0
poss:   sub 7
        jp p,noborder
   
        ld  (BRDMSKDST+0),a
        ld  (BRDNEWORG+0),a
        sub 15*16
        ld  (BRDNEWDST+0),a         ; A compreso tra 0 e 15
        jp border       
borderSX
        ld  a,(XPOS)
        bit 3,a
        jp  z,pos
        or  #F0
pos:    add a,7
        jp m,noborder
        ld  (BRDMSKDST+0),a         ; A compreso tra 0 e 15
        add a,15*16
        ld  (BRDNEWORG+0),a
        ld  (BRDNEWDST+0),a
border

;        ld  a,(BRDMSKDST)           ; copia solo ogni 2 linee i punti pari
;        and 1
;        ret nz

        wait_rdy                    
        vdp_cmd BRDMSKDST,11        ; cancella bordo con una linea nera nella pagina visibile

        rept    4
            call setclrxyshp
        endm
        
        wait_rdy                    
        vdp_cmd BRDNEWORG,15         ; copia una nuova linea nell'altro bordo nella pagina visibile
       
        ret

noborder
        ret


;**************************************************************

; comandi VDP traccia blocco PIENO veloce (HMMV)

BRDMSKPGX
        db  #00,#00         ; destinazione X
        db  #00             ; destinazione Y
        db  #00             ; pagina destinazione
        db  #02,#00         ; dimensione blocchi X
        db  8*VSCSZ,#00     ; dimensione blocchi Y
        db  #00             ; colore
        db  #00             ; R#45 destinazione e direzione
        db  #C0             ; comando HMMV 

; comandi VDP traccia blocco PIENO logico (LMMV)

BRDMSKDST        
        db  #00,#00         ; destinazione X
        db  #00             ; destinazione Y
        db  #01             ; pagina destinazione
        db  #01,#00          ; dimensione blocchi X;        db  #02,#00          ; dimensione blocchi X
        db  16*VSCSZ,#00    ; dimensione blocchi Y
        db  0               ; colore
        db  #00             ; R#45 destinazione e direzione
        db  #80             ; #80 comando LMMV e operazione logica (db  #C0 per comando HMMV)
        
; comandi VDP copia logica di una linea (LMMM)
BRDNEWORG        
        db  #00,#00         ; origine X
        db  #00             ; origine Y
        db  #03             ; pagina origine
BRDNEWDST
        db  #00,#00         ; destinazione X
        db  #00             ; destinazione Y
        db  #01             ; pagina destinazione
        db  #01,#00          ; dimensione blocchi X;        db  #02,#00          ; dimensione blocchi X
        db  16*VSCSZ,#00    ; dimensione blocchi Y
        db  0               ; colore
        db  #00             ; R#45 destinazione e direzione
        db  #90             ; #90 comando LMMM e operazione logica  (db  #D0 per comando HMMM)




;************************************************************
;                 ROUTIN1 (SCROLLING)
; Main screen processing: set X&Y scroll and page swap.
;************************************************************

verso   db   1            ; 1 ho bordo entrante a destra e scorro le colonne da sinistra a destra
                          ; 0 ho bordo entrante a sinistra e scorro le colonne da destra a sinistra
pgX     db   0            ; Copia temporanea della pagina di lavoro


       
swap_screen
        LD  A,(ACTPG)
        and a
        LD  A,#1F               ; Attiva la pagina video corrente sulla base di quella in cui in VDP lavora
        JP  NZ,pag0
pag1:   LD  A,#3F
pag0:   vdp 2      

        LD  A,(XPOS)            ; MUOVI LO SCHERMO (X scroll)
        vdp 18
        LD  A,(YPOS)            ; MUOVI LO SCHERMO (Y scroll)
        vdp 23
        ret
                                ; Decide in che verso fare la scansione dello schermo 
plot_screen 
        ld a,(verso)
        and a
        jp z,BordoSX_entrante
        jp BordoDX_entrante


BordoSX_entrante              
    ; ho bordo entrante a sinistra e scorro le colonne da destra a sinistra
    ; mi aspetto di avere L83B9 che punta all'angolo in alto a destra
    ; le ascisse (L83AA+4) = (L88AA+4) = (L93AA+4)-4 = 16*15
    ; le pagine  (L88AA+7) = (L93AA+7) = (BRDMSKPGX+3) = (ACTPG)
    ; l'ascissa del mascheramento (BRDMSKPGX+0) = 0
    
        ld    a,(L83AA+4)
        and a           ; sono all'ultima colonna ?
        push  af
        call z,Set_pag3

        call DWLNE

        pop af          ; sono all'ultima colonna ?
        call z,Set_pagX

        ld    a,(L83AA+4)     ; setta ascisse
        sub   #10
        ld    (L83AA+4),a
        ld    (L88AA+4),a
        add  a,4
        ld    (L93AA+4),a

        xor   a               ; setta ordinate
        LD  (L83AA+6),A
        LD  (L88AA+6),A
        ld    a,16-3   
        LD  (L93AA+6),A
            
        ld hl,(L83B9)         ; muovi colonna
        dec hl
        ld (L83B9),hl
        ret

BordoDX_entrante              
    ; ho bordo entrante a destra e scorro le colonne da sinistra a destra
    ; mi aspetto di avere L83B9 che punta all'angolo in alto a sinistra
    ; le ascisse (L83AA+4) = (L88AA+4) = (L93AA+4)-4 = 0
    ; le pagine  (L88AA+7) = (L93AA+7) = (BRDMSKPGX+3) = (ACTPG)
    ; l'ascissa del mascheramento (BRDMSKPGX+0) = 15*16
        
        ld    a,(L83AA+4)
        cp    16*15           ; sono all'ultima colonna ?
        push  af
        call z,Set_pag3
    
        call DWLNE
        
        pop af                ; sono all'ultima colonna ?
        call z,Set_pagX
    
        ld    a,(L83AA+4)     ; setta ascisse
        add   a,#10
        ld    (L83AA+4),a
        ld    (L88AA+4),a
        add  a,4
        ld    (L93AA+4),a
        
        xor   a               ; setta ordinate
        LD  (L83AA+6),A
        LD  (L88AA+6),A
        ld    a,16-3   
        LD  (L93AA+6),A
        
        ld hl,(L83B9)         ; muovi colonna
        inc hl
        ld (L83B9),hl
        ret

Set_pag3
        ld    a,15*16         ; setta ascisse
        ld    (L83AA+4),a
        ld    (L88AA+4),a
        add  a,4
        ld    (L93AA+4),a
        ld    a,(ACTPG)       ; setta pagina
        ld  (pgX),a
        ld    a,3
        ld    (ACTPG),a
        ld    (L88AA+7),a
        ld    (L93AA+7),a
        ret
Set_pagX
        ld  a,(pgX)
        ld    (ACTPG),a
        ld    (L88AA+7),a
        ld    (L93AA+7),a
        ret

;************************************************************

setSX 
        xor a                 ; ho bordo entrante a sinistra e scorro le colonne da destra a sinistra
        ld  (verso),a
                              ; pongo (L83B9) che punta all'angolo in alto a destra
        ld bc,15              ; viene sommato a (L83B9) in uscita
    
        ld    a,16*15         ; le ascisse (L83AA+4) = (L88AA+4) = (L93AA+4)-4 = 16*15
        ld (L83AA+4),a
        ld (L88AA+4),a
        add a,4
        ld (L93AA+4),a
    
        ld    a,(ACTPG)       ; le pagine  (L88AA+7) = (L93AA+7) = (BRDMSKPGX+3) = (ACTPG)
        ld    (L88AA+7),a
        ld    (L93AA+7),a
        ld    (BRDMSKPGX+3),a
            
        xor a                 ; l'ascissa del mascheramento (BRDMSKPGX+0) = 0
        ld (BRDMSKPGX+0),a
        ret

;************************************************************

setDX 
        ld  a,1               ; ho bordo entrante a destra e scorro le colonne da sinistra a destra
        ld  (verso),a
                              ; pongo (L83B9) che punta all'angolo in alto a sinistra
        ld bc,0               ; viene sommato a (L83B9) in uscita
    
        xor   a               ; le ascisse (L83AA+4) = (L88AA+4) = (L93AA+4)-4 = 0
        ld (L83AA+4),a
        ld (L88AA+4),a
        add a,4
        ld (L93AA+4),a
    
        ld    a,(ACTPG)       ; le pagine  (L88AA+7) = (L93AA+7) = (BRDMSKPGX+3) = (ACTPG)
        ld    (L88AA+7),a
        ld    (L93AA+7),a
        ld    (BRDMSKPGX+3),a
        
        ld    a,16*15         ; l'ascissa del mascheramento (BRDMSKPGX+0) = 15*16
        ld (BRDMSKPGX+0),a
        ret
    
;************************************************************


TEST        
               
        ld  a,(TIMER)
        and a
        ret nz
        
        LD  HL,NVPSWP           ; Contatore del numero di pageswap video; serve per le animazioni dei blocchi di fondale
        INC (HL)

; SCROLL ORIZZONTALE

        LD  HL,(L8100)          ; HL punta alla schermata corrente
        LD  A,(XDIR)
        CP   1                  ; scroll a destra: bordo entrante a DX
        JP  Z,L82CA
        CP  -1                  ; scroll a sinistra: bordo entrante a SX
        JP  Z,L82DC
        xor a                   ; non va da nessuna parte
        ld  (XDIR2),a

        LD  A,(XPOS)            ; non scrollare orizzontalmente
        CP  -8 and #0f        ; e' -8 ?
        call    z,setDX         ; il bordo entrante è a DX

        LD  A,(XPOS)            ; non scrollare orizzontalmente
        CP  7 and #0f         ; è 7 ?  
        call    z,setSX         ; il bordo entrante è a SX
        JP  L82F4               

L82CA   INC HL
        call      setDX         ; bordo entrante a DX 
        
        LD  A,(XPOS)            ; prova a iniziare scroll a DESTRA
        CP  -8 and #0f        ; e' -8 ?
        JP  Z,L82E8             ; sei già tutto a destra e puoi scrollare in questo turno
        
                                ; altrimenti XPOS e' 7 e puoi scrollare a destra 
                                ; di un blocco mettendolo ad -8

        xor a                   ; sposta bordo a destra 
        ld  (XDIR2),a
        ld  a,(-8 and #0f)  or  #80
        ld  (TMPXPOS),a
        JP  L82F4

L82DC   DEC HL
        call    setSX           ; bordo entrante a SX
        
        LD  A,(XPOS)            ; prova a iniziare scroll a SINISTRA
        CP  7 and #0f         ; è 7 ?     
        JP  Z,L82E8             ; sei già tutto a sinistra e non puoi scrollare ulteriormente questo turno
                                ; altrimneti XPOS e' -8 e puoi scrollare a sinistra
                                ; di un blocco mettendolo ad 7

        xor a                   ; sposta bordo a sinistra 
        ld  (XDIR2),a
        ld  a,(7 and #0f)  or  #80
        ld  (TMPXPOS),a
        
        JP  L82F4

L82E8   
        ld  a,(XDIR)            ; blocca incrementi per 16 frame
        ld  (XDIR2),a
        xor a
        ld  (TMPXPOS),a        ; cancellali dopo ogni uso

; SCROLL VERTICALE

L82F4           
        LD  A,(YDIR)
        CP  1
        JP  Z,L8324             ; scroll giu' 
        CP  -1 
        JP  Z,L8334             ; scroll su

        xor a                   ; non va da nessuna parte
        ld  (YDIR2),a

        LD  (L8100),HL
        add hl,bc
        LD  (L83B9),HL          ; Memorizza qui la posizione iniziale della scansione blocchi per il ridisegno pagina
        RET

L8324   ld  de,128              ; scroll giu' 

        ADD HL,DE
        LD  (L8100),HL
        add hl,bc
        LD  (L83B9),HL          ; Memorizza qui la posizione iniziale della scansione blocchi per il ridisegno pagina

        ld  a,(YPOS)            ; prova ad andare giù
        cp  15
        jp  nz,L8338    

        xor a                   ; sposta bordo in basso
        ld  (YDIR2),a
        ld  a,#0  or  #80
        ld  (TMPYPOS),a         ; tra 16 frame metti la riga di blocchi nascosta in basso
        RET

L8334   ld  de,-128

        ADD HL,DE
        LD  (L8100),HL
        add hl,bc
        LD  (L83B9),HL          ; Memorizza qui la posizione iniziale della scansione blocchi per il ridisegno pagina

        ld  a,(YPOS)            ; prova ad andare su
        and a
        jp  nz,L8338
    
        xor a                   ; sposta bordo in alto
        ld  (YDIR2),a
        ld  a,#0F  or  #80
        ld  (TMPYPOS),a         ; tra 16 frame metti la riga di blocchi nascosta in alto
        RET

L8338   
        ld  a,(YDIR)
        ld  (YDIR2),a
        xor a
        ld  (TMPYPOS),a        ; cancellali dopo ogni uso

        RET


TMPXPOS     db  #00
TMPYPOS     db  #00

;************************************************************
;
; comandi VDP copia blocco FISSO

L83AA   db  #00,#00     ; origine X
        db  #00         ; origine Y
        db  #02     
        db  #00,#00     ; destinazione X
        db  #00         ; destinazione Y
ACTPG   db  #01         ; pagina destinazione
        db  #10,#00
        db  #10,#00     ; dimensione blocchi
        db  #00,#00,#D0

; comandi VDP copia blocco TRASPARENTE

L88AA   db  #00,#00     ; origine X
        db  #00         ; origine Y
        db  #02     
        db  #00,#00     ; destinazione X
        db  #00         ; destinazione Y
        db  #01         ; pagina destinazione
        db  #10,#00
        db  #10,#00     ; dimensione blocchi
        db  #00,#00,10011000b

; comandi VDP copia blocco PIOLO

L93AA   db  #00,#00     ; origine X
        db  9*16,#02    ; origine Y
        db    4,#00     ; destinazione X
        db  16-3        ; destinazione Y
        db  #01         ; pagina destinazione
        db   8,#00
        db   3,#00      ; dimensione blocchi
        db  #00,#00,#D0

; comandi VDP copia blocco colori sprite

xorg    db  #00,#00     ; origine X
yorg    db  #00,#03     ; origine Y
xdest   db  #00,#00     ; destinazione X
ydest   db  #00,#00     ; destinazione Y
xdim    db  #10,#00
        db  #01,#00     ; dimensione blocchi
        db  #00,#00,#D0

L83B9   DW  0           ; POSIZIONE LINEA TRA UNA SCANSIONE E LA SUCCESSIVA

PIOLI       db  #54,#64,#74,#84
PIOLIY      db    0,  4,  8, 12

;************************************************************
;           SUB BLOCCHI GESTISCE NUVOLE FONDALE
;************************************************************
NUVOLE
        ld  a,(L8100)
;        add a,a         ;X2
        ld  d,a
        ld  a,l
        and #07
        x16 A
        sub d
        and #7f

        LD  (L83AA),A       ; origine X
        and #01         
        ld  c,0             ; Nuvole pari
        jp  nz,PARI
        ld  c,5*16          ; Nuvole dispari
PARI    

        ex  de,hl
        ld  hl,(L8100)
        add hl,hl   
        ld  a,h
;        add a,a         ;X2        
        ex  af,af'

        ld  h,d
        ld  l,e
        add hl,hl   
        ld  a,h
        and #03
        x16 A
        ex  de,hl

        ex  af,af'
        ld  d,a
        ex  af,af'

        sub d
        and #3F
    
        add a,c
        LD  (L83AA+2),A       ; origine Y

        ld  a,3
        LD  (L83AA+3),A       ; pagina origine Y

        JP  SETBLK

;************************************************************

DWLNE   
                             ; PREPARA LETTURA REGISTRO 2
        LD  A,#02
        vdp #0f

;******************************************************************
;          SCRIVE BLOCCHI PIENI


;        call    initMov     ; inizializza movimento sprites
        
        LD  B,VSCSZ          ; VSCSZ blocchi per colonna
        LD  HL,(L83B9)

NWBLK   
        LD  A,(HL)  
        cp  #55
        jp  z,NUVOLE        ; E’ fondale?
    
        EXX
        ld  hl,ATTRTILES
        ld  d,0
        ld  e,a
        add hl,de
        LD  A,(HL)
        EXX
        ld c,a
        
        bit 0,c             ; E' trasparente e servono le nuvole?
        jp  nz,NUVOLE
        bit 1,c             ; e’ animato ma non trasparente?
        
        LD  A,(HL)      
        CALL    nz,L8428        
        LD  D,A
        AND #F0
        LD  (L83AA+2),A       ; origine Y
        ld  a,2
        LD  (L83AA+3),A       ; pagina origine Y
        LD  A,D
        x16 A
        LD  (L83AA+0),A       ; origine X

SETBLK
        EXX
;        call    nxtsprtMov  ; muove il prossimo sprite
;        call    nxtsprtMov  ; muove il prossimo sprite

        wait_rdy            ; ASPETTA VDP PRONTO
        vdp_cmd L83AA,15
        call setclrxyshp

        EXX

        LD  DE,128          ; PREPARA LA STAMPA DI UNA NUOVA LINEA
        ADD HL,DE

        LD  A,(L83AA+6)       ; Sposta destinazione un blocco in basso
        ADD A,#10
        LD  (L83AA+6),A

        DJNZ    NWBLK
;        call    endsprtMov      ;  muove eventuali sprite residui
        
;************************************************************
;       cancella un blocco di bordo con un rettangolo nero nella pagina invisibile
;************************************************************

        ld a,(BRDMSKPGX+0)
        and 1
        jp  z,partedigiu
partedisu
        xor a
        ld (BRDMSKPGX+2),a
        jp cancella
partedigiu
        ld  a,8*VSCSZ
        ld (BRDMSKPGX+2),a
cancella
        call setclrxyshp
        wait_rdy                    
        vdp_cmd BRDMSKPGX,11       

        ld a,(BRDMSKPGX+0)
        inc a
        ld (BRDMSKPGX+0),a          ; Prepara ascissa del blocco nero

;************************************************************
;         LOOP PIOLI
;************************************************************
pioli
        LD  B,VSCSZ         ; VSCSZ blocchi per colonna
        LD  HL,(L83B9)
NWBLK2
        LD  A,(HL)      

        EXX                 ; pioli
        ld  bc,4
        ld  hl,PIOLI
        cpir    
        jp  nz,NOpiolo

        ld  de,PIOLIY-PIOLI-1
        add hl,de
        ld  a,(hl)
        add a,9*16          ; posizione Y dei pioli in pag 2
        LD  (L93AA+2),A       ; origine Y

        wait_rdy       ; ASPETTA VDP PRONTO
        vdp_cmd L93AA,15
NOpiolo
    
        EXX

        LD  DE,128      ; PREPARA LA STAMPA DI UNA NUOVA LINEA
        ADD HL,DE

        LD  A,(L93AA+6)       ; Sposta destinazione un blocco in basso
        ADD A,#10
        LD  (L93AA+6),A

        DJNZ    NWBLK2

;************************************************************
;          SCRIVE BLOCCHI TRASPARENTI
;************************************************************

        LD  B,VSCSZ          ; VSCSZ blocchi per colonna
        LD  HL,(L83B9)

        xor a
        ld  (nfnd),a
        
NWBLK3  
        LD  A,(HL)      
        EXX
        ld  hl,ATTRTILES
        ld  d,0
        ld  e,a
        add hl,de
        LD  A,(HL)
        EXX
        ld  c,a
        
        bit 0,c 
        jp  z,NXBLK         ; NON E’ TRASPARENTE
        bit 3,c 
        jp  nz,NXBLK        ; e’ un piolo

        bit 1,c             ; e’ animato?
        LD  A,(HL)      
        CALL    nz,L8428        
        LD  D,A
        AND #F0
        LD  (L88AA+2),A       ; origine Y
        LD  A,D
        x16 A
        LD  (L88AA+0),A       ; origine X
        
        EXX

        call setclrxyshp
        
        wait_rdy               ; ASPETTA VDP PRONTO
        vdp_cmd L88AA,15
        EXX
        
        ld  a,(nfnd)
        inc a
        cp  2                 ; numero max di blocchi trasparenti per colonna
        jp z,exitLoop         ; Exit se non puoi mettere altri blocchi
        ld  (nfnd),a

NXBLK   
        LD  DE,128            ; PREPARA LA STAMPA DI UNA NUOVA LINEA
        ADD HL,DE

        LD  A,(L88AA+6)       ; Sposta destinazione un blocco in basso
        ADD A,#10
        LD  (L88AA+6),A

        DJNZ    NWBLK3
exitLoop
        
        RET             ; FINITO

nfnd    db  0

;************************************************************
;         ANIMAZIONE FONDALE
;************************************************************


L8428   
        bit 4,c    
        JP  z,L8445
        AND 7           ; ANIMAZIONE BLOCCHI FONDALE CON 8 FRAME
        x8  A
        EXX
        LD  H,0
        LD  L,A
        LD  DE,TANIM2
        ADD HL,DE
        LD  A,(NVPSWP)
        AND 7
        LD  D,0
        LD  E,A
        ADD HL,DE
        LD  A,(HL)
        EXX
        RET

L8445   AND 7           ; ANIMAZIONE BLOCCHI FONDALE CON 4 FRAME
        x4  A
        EXX
        LD  H,0
        LD  L,A
        LD  DE,TANIM1
        ADD HL,DE
        LD  A,(NVPSWP)
        AND 3
        LD  D,0
        LD  E,A
        ADD HL,DE
        LD  A,(HL)
        EXX
        RET

TANIM1  
    db  #F8,#F9,#FA,#FB     ; Ruota
    db  #FC,#FD,#FE,#FF     ; Ruota
    db  "D","E","F","G"     ; Ruota
    db  "H","I","J","K"     ; Ruota
    db  #D0,#D2,#D4,#D6     ; Ascensore
    db  #D1,#D3,#D5,#D7     ; Ascensore
    db  #E0,#E2,#E4,#E6     ; Ascensore
    db  #E1,#E3,#E5,#E7     ; Ascensore

TANIM2  
    db  #DB,#DB,#DB,#DB,#EC,#ED,#EE,#EF     ; Sfera
    db  #E8,#E9,#EA,#EB,#EB,#EA,#E9,#E8     ; Punte
    db  #08,#09,#0A,#0B
    db  "(",")","*","+"
    db  #0C,#0D,#0E,#0F
    db  ",","-",".","/"
    db  #10,#11,#12,#13
    db  "0","1","2","3"
    db  #14,#15,#16,#17
    db  "4","5","6","7"
    db  #18,#19,#1A,#1B
    db  "8","9",":",";"
    db  #1C,#1D,#1E,#1F
    db  "<","=",">","?"

    ;********************************************************
;
; 7 6 5 4 3 2 1 0
; BIT 0 : NUVOLE = 1; NULLA =0
; BIT 1 : ANIMATO = 1; FISSO = 0
; BIT 2 : PIENO = 0; TRASPARENTE = 1 ( => nuvole)
; BIT 3 : PIOLI ( => nuvole)
; BIT 4 : ANIMATO su 8 frame = 1; FISSO = 0
; BIT 5 : 
; BIT 6 : 
; BIT 7 : 
;
ATTRTILES
;       0 1 2 3 4 5 6 7 8 9 a b c d e f 
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;   0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;   1
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;   2
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1 ;   3
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;   4
    db  1,1,1,1,9,0,0,0,0,0,0,0,0,0,0,0 ;   5
    db  1,1,1,1,9,0,0,0,0,0,0,0,0,0,0,0 ;   6
    db  1,1,1,1,9,0,0,0,0,0,0,0,0,0,1,1 ;   7
    db  1,1,1,1,9,0,0,0,0,0,0,0,0,0,1,1 ;   8
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;   9
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;   A
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;   B
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;   C
    db  2,2,2,2,2,2,2,2,0,0,0,3,1,1,1,1 ;   D
    db  2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3 ;   E
    db  19,19,19,19,19,19,19,19,2,2,2,2,2,2,2,2 ;   F

;********************************************************

; 7400h     colori sprite
; 7600h     attributi sprite
; 7800h     forme sprite

nextXPOS    db  0
nextYPOS    db  0
sprtBuff_p  dw spritbuff
sprtAttr_p  dw SPTATR
sprtVAttr_p dw 7600h
sprtVClr_p  dw 7400h
sprtVShp_p  dw 7800h

MSXSPRT EQU 20

sprtcurr    dw  MSXSPRT 

endclrxyshp
        ld  a,(sprtcurr)
        and a
        ret z
      
        ld  b,a
rn12    exx
        call setclrxyshp
        exx
        djnz    rn12
        ret

setclrxyshp
        ld  a,(sprtcurr)
        and a
        ret z
        dec a
        ld  (sprtcurr),a
        push af
        
        IF  DEBUG2 
            vdp 7
        ENDIF
        
        ld  hl,(sprtVAttr_p)
        vrmaddr_w
        ld  de,4
        add hl,de
        ld  (sprtVAttr_p),hl

        ld  hl,(sprtAttr_p)
        ld  c,vdpport0

        ld  a,(nextYPOS)
        add a,(hl)
        out (vdpport0),a
        inc hl

        ld  a,(nextXPOS)
        add a,(hl)
        out (vdpport0),a
        inc hl
        OUTI
        inc hl
        ld  (sprtAttr_p),hl
        
        pop af
        jp  nz,rn14
        ld  a,216           ; spegne gli altri sprite
        out (vdpport0),a
        out (vdpport0),a
rn14
        ld  hl,(sprtVClr_p)
        vrmaddr_w
        ld  de,16
        add hl,de
        ld  (sprtVClr_p),hl

        ld  ix,(sprtBuff_p)

        ld  l,(ix+0)      
        ld  h,0
        x16 hl
        ld  de,SPRTCOL        
        add hl,de
        rept 16
        OUTI
        endm

        IF  DEBUG4
              ld  hl,(sprtVShp_p)
              vrmaddr_w
              ld  de,32
              add hl,de
              ld  (sprtVShp_p),hl

              LD  l,(ix+32)    
              ld  h,0
              x32 hl
              ld  de,SPRTSHP        
              add hl,de
              rept 32
              OUTI
              endm
        ENDIF
      
        inc ix      
        ld  (sprtBuff_p),ix

        IF  DEBUG2 
            xor a
            vdp 7
        ENDIF

        ret 

intsetclrxyshp

        ld  a,001b
        ; bits A16-A14
        vdp 14    

        ld a,MSXSPRT 
        ld  (sprtcurr),a

        ld hl,spritbuff
        ld  (sprtBuff_p),hl
        
        ld  hl,SPTATR
        ld  (sprtAttr_p),hl

;gestione offset
        ld  de,(XDIR2)          ; d = (YDIR2), e = (XDIR2)

        ld a,(TIMER)
        cp 15                   ; al prossimo frame si cambia quadro?
        push    af              ; salva il flag
        jp  nz,rn15
        
        ld  a,(TMPYPOS)
        bit 7,a                 ; sto invertendo direzione alto-basso e viceversa ?
        jp  z,rn15

        and 15                  ; sto invertendo direzione: usa offeset in TMPYPOS
        jp  rn16
rn15
        ld  a,(YPOS)            ; non sto invertendo direzione: usa offeset normale
        add a,d
        and 15
rn16
        ld  (nextYPOS),a

        pop     af              ; recupera il flag        
        jp  nz,rn17
                                ; al prossimo frame si cambia quadro
        ld  a,(TMPXPOS)
        bit 7,a                 ; sto invertendo direzione destra-sinistra e viceversa ?
        jp  z,rn17

        and 15                  ; sto invertendo direzione: usa offeset in TMPXPOS
        jp  rn13
rn17 
        ld  a,(XPOS)            ; non sto invertendo direzione: usa offeset normale
        bit 3,a
        jp  z,rn13
        or  #F0
rn13 
        add a,e
        add a,8
        and 15

        ld  (nextXPOS),a

        
        ld a,(TIMER)
        and 1
        and a
        jp  z,swapsprt

        ld  a,223
        vdp 5       ; visualizza colori e attributi a 6C00h
        ld  a,14
        vdp 6       ; visualizza forme a 7000h 

        ld hl,7600h
        ld  (sprtVAttr_p),hl

        ld  hl,7400h
        ld  (sprtVClr_p),hl

        ld  hl,7800h
        ld  (sprtVShp_p),hl

        ret

swapsprt
        ld  a,239
        vdp 5       ; visualizza colori e attributi a 7400h
        ld  a,15
        vdp 6       ; visualizza forme a 7800h 

        ld hl,6E00h
        ld  (sprtVAttr_p),hl

        ld  hl,6C00h
        ld  (sprtVClr_p),hl

        ld  hl,7000h
        ld  (sprtVShp_p),hl

        ret

;********************************************************


spritbuff   
             db  0 , 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15 ;   Forme (vanno a coppie)
             db  16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31 ;   Forme (vanno a coppie)
             db  0 , 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15 ; Colori (vanno a coppie)
             db  16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31 ; Colori (vanno a coppie)



    ;*********************************************************
    ;       ROUTIN2 (GESTIONE SPRITES)


INDIR   LD  A,(KEYSTK)
    AND A
    JP  Z,KEY

STICK   LD  A,#0F
    OUT (#A0),A
    LD  A,#8F
    OUT (#A1),A
    LD  A,#0E
    OUT (#A0),A
    IN  A,(#A2)
    RET


KEY LD  C,255
    LD  A,8
    OUT (#AA),A
    IN  A,(#A9)

RI  BIT 7,A
    JP  NZ,LE
    RES 3,C 
    JP  UP
LE  BIT 4,A
    JP  NZ,UP
    RES 2,C
UP  BIT 5,A
    JP  NZ,DW
    RES 0,C
DW    bit   6,a
    jp  nz,FIRE
    res 1,c
FIRE    BIT 0,A
    JP  NZ,FIN
    RES 4,C
FIN LD  A,C
    RET 

;***************************************

GESTINC 
        ; GESTIONE INCREMENTI

    xor     a       ;   per test
    ld  (XDIR),a
    ld  (YDIR),a

    CALL    INDIR
    LD  (JOY),A

    BIT 3,A
    CALL    Z,SPDS
    LD  A,(JOY)
    BIT 2,A
    CALL    Z,SPSN

    LD  A,(JOY)
    BIT 1,A
    CALL    Z,SPDW
    LD  A,(JOY)
    BIT 0,A
    CALL    Z,SPUP
    
    RET


;***************************************
SPSN
    ld  a, -1      ;   per test
    ld  (XDIR),a
    RET

SPDS    
    ld  a, 1            ;   per test
    ld  (XDIR),a
    RET

SPUP    
    ld  a,-1      ;   per test
    ld  (YDIR),a
    RET

SPDW   
    ld  a, 1            ;   per test
    ld  (YDIR),a
    RET

;***********************************


;******************************
Xpatch  db  8
Ypatch  db  -1
XYoffset     dw  0
TBSPRT_PTR   dw  TABSPRT
SPTATR_PTR   dw  SPTATR
SPTCOLLS_PTR dw SPTCOLLS
nsprt_CR     dw 0

initPSPRT
        ld  a,(nsprt)       ; max 32 sprite visualizzati
        and a
        ld  (nsprt_CR),a
        jp  z,nosprite
        x4  a
        inc a
        ld  (nbyteattsprt),a
        
        LD  IX,TABSPRT
        ld  (TBSPRT_PTR),ix
        
        ld  iy,SPTATR
        ld  (SPTATR_PTR),iy
        
        ld  de,SPTCOLLS
        ld  (SPTCOLLS_PTR),de
        ret

nosprite 
        ld  a,1
        ld  (nbyteattsprt),a
        LD  A,#D8           ; SPEGNE GLI EVENTUALI NON ATTIVI
        ld  (SPTATR),a
        RET
        
setBrdrMsk        
        bit 7,(IX+3)
        jp    nz,sprtSX
        bit 6,(IX+3)
        jp    nz,sprtDX
        ret
        
setframe
        ld  a,1
        x4  a
        ld  (iy+2),a
        ld  a,2
        x4  a
        ld  (iy+6),a
        ret

finesprite
        ld  ix,(SPTATR_PTR)
        LD  A,#D8           ; SPEGNE GLI EVENTUALI NON ATTIVI
        ld  (ix+0),a
        RET

putNxtSprt
        ld  a,(nsprt_CR)
        and a
        jp z,finesprite
        dec a
        ld  (nsprt_CR),a

        ld  hl,(XYoffset)
        ld  ix,(TBSPRT_PTR)
        ld  iy,(SPTATR_PTR)
                
        call    setBrdrMsk
        call    XYadjust
        call    setcol
        call    setframe
        
        ld  de,8
        add iy,de
            
        ld  de,4
        add ix,de
    
        ld  (TBSPRT_PTR),ix
        ld  (SPTATR_PTR),iy

        ret
XYadjust
        LD  A,(IX+0)
        add a,l
        ld  (iy+0),a        ; verticale
        ld  (iy+4),a        ; verticale
    
        LD  A,(IX+1)
        add a,h
        ld  (iy+1),a        ; orizzontale
        ld  (iy+5),a        ; orizzontale
        ret

;******************************


setcolC
        ld  de,(SPTCOLLS_PTR)
        ld  (de),a
        inc de
        ld  (SPTCOLLS_PTR),de
        ret
setcol
        bit 7,(IX+3)
        jp  z,noseteclk
        ld  a,2
        call    setcolC
        ld  a,3
        call    setcolC
        ret
noseteclk
        ld  a,4
        call    setcolC
        ld  a,5
        call    setcolC
        ret
sprtSX
        LD  A,(IX+0)
        add a,l
        ld  (iy+0),a        ; verticale
        ld  a,16
        add a,h
        ld  (iy+1),a        ; orizzontale
        xor a
        ld  (iy+2),a        ; qui dovrebbe andare il blocco pieno
        
        ld  a,1
        call setcolC

        ld  de,4
        add iy,de
        ret
sprtDX
        LD  A,(IX+0)
        add a,l
        ld  (iy+0),a        ; verticale
        ld  a,15*16
        add a,h
        ld  (iy+1),a        ; orizzontale
        xor a
        ld  (iy+2),a        ; qui dovrebbe andare il blocco pieno

        xor a
        call setcolC

        ld  de,4
        add iy,de
        ret

    ;****************************************************
    ;         TABELLE SPRITES


nsprt       db  0

nbyteattsprt   db  0
nbytecolsprt   dw  0
ncolsprt       db  0

SPTCOLLS    ds  1; 16


SPTATR      db  0,0,0,0
            db  0,16,1,0
            db  0,32,2,0
            db  0,48,3,0
            db  0,64,4,0
            db  0,80,5,0
            db  0,96,6,0
            db  0,112,7,0
            db  16,0,8,0
            db  16,16,9,0
            db  16,32,10,0
            db  16,48,11,0
            db  16,64,12,0
            db  16,80,13,0
            db  16,96,14,0
            db  16,112,15,0
            db  32,0,16,0
            db  32,16,17,0
            db  32,32,18,0
            db  32,48,19,0
            db  32,64,20,0
            db  32,80,21,0
            db  32,96,22,0
            db  32,112,23,0
            db  48,0,24,0
            db  48,16,25,0
            db  48,32,26,0
            db  48,48,27,0
            db  48,64,28,0
            db  48,80,29,0
            db  48,96,30,0
            db  48,112,31,0

       
;*****************************************************
;   byte            Y
;   byte            X
;   byte            [         sprite num         ]
;   byte            ECK,MSL,  0, 0,[  sprite col ]
;
TABSPRT     ds  4*16            


CR_TABSPRT  dw  TABSPRT
CR_REALXY   dw  REALXY
CR_nVsprt   db  20

initMov
            ld  hl,TABSPRT
            ld  (CR_TABSPRT),hl
            
            ld  hl,REALXY
            ld  (CR_REALXY),hl
        
            ld  a,20            ; numero di sprite virtuali
            ld  (CR_nVsprt),a
            
            xor a               ; numero di posizioni a video (max 32)
            ld  (nsprt),a

            ld  a,(Xpatch)      ; deve passare in nxtxy
            ld  h,a
            LD  a,(XPOS)        ; CALCOLA OFFSET
            bit 3,a
            jp  z,pos1
            or #F0
pos1        add a,h             ; da -8,+7 a +0,+15 o +1,+16
            ld  h,a

            ld  a,(Ypatch)
            ld  l,a
            LD  a,(YPOS)        ; CALCOLA OFFSET
            add a,l
            ld l,a              ; da +0,15 a -1,+14 o +0,+15
                                ; IN H E L GLI OFFSET VERTICALE E ORIZZONTALE
            ld  (XYoffset),hl
            ret
        
nxtsprtMov
            ld  a,(CR_nVsprt)
            and a
            ret z
            dec a
            ld  (CR_nVsprt),a

            ld  ix,(CR_TABSPRT)
            ld  iy,(CR_REALXY)

            call    movcurr ; INTEGRARE PUTSPRT CON MOVSPRT???????

            ld  de,6
            add iy,de

            ld  (CR_TABSPRT),ix
            ld  (CR_REALXY),iy
       
            ret

endsprtMov  ld  a,(CR_nVsprt)
            and a
            ret z

            ld  ix,(CR_TABSPRT)
            ld  iy,(CR_REALXY)
        
            ld  b,a             ; numero di sprite virtuali restanti
        
nxtsprtM    push    bc
            call    movcurr
            pop     bc
            ld  de,6
            add iy,de
            djnz    nxtsprtM
           
            ret

;***************

movcurr        
            bit 7,(iy+0)
            ret nz

;
;ld  a,(iy+0)
;   GESTIONE ANIMAZIONE
;
 
            ld  a,(nsprt)
            cp  32+1
            ret nc              ; esci se eccede il numero di sprt visualizzabili

            xor a
            ld (ix+3),a
             
            call    xconv
            call    yconv

            ld  de,4
            add ix,de

            ld  hl,nsprt
            inc (hl)
            inc (hl)
            ret


yconv       ld  l,(iy+4)
            ld  h,(iy+5)
            ld  de,(scrY)
            xor a
            sbc hl,de
            ld  b,h
            ld  c,l        
            ld  de,16
            xor a
            adc hl,de

            jp  p,Ypositivo         ; Y-scrY>=-16
            jp  fuorischermo
            
Ypositivo   ld  h,b
            ld  l,c
            ld  de,VSCSZ*16         
            xor a
            sbc hl,de
            jp  p,fuorischermo      ; Y-scrY>=VSCSZ*16
            
            ld (ix+0),c
            ret
                  
        
xconv       ld  l,(iy+2)
            ld  h,(iy+3)
            ld  de,(scrX)
            xor a
            sbc hl,de
            ld  b,h
            ld  c,l        

            jp  p,Xpositivo         ; X-scrX>=0

            ld  de,16               ; X-scrX<0
            xor a
            adc hl,de 
            jp  m,fuorischermo      ; X-scrX<-16

            call setbordoSX         ; scrX-16<=X<scrX

            ld (ix+1),c
            ret

Xpositivo   ld  de,15*16
            xor a
            sbc hl,de
            jp  p,fuorischermo  ; X-scrX>=240

            ld  h,b
            ld  l,c
            ld  de,14*16
            xor a
            sbc hl,de

            res 6,(ix+3)            ;       bit bordo sinistro              
            res 7,(ix+3)            ;       bit earlyclock    
            
            call  p,setbordoDX      ; 224<=X-scrX<240

            ld (ix+1),c
            ret

fuorischermo    pop af          ; interrompe la routine superiore
                ret
    
setbordoSX:     ld  a,32        ;               metti bordo Sx
                add a,c
                ld  c,a
                set 7,(ix+3)    ;       bit earlyclock                
                res 6,(ix+3)    ;       bit bordo sinistro        

                ld  hl,nsprt    ;       conta bordo SX
                inc (hl)
                ret
        
setbordoDX                      ;       metti bordo DX  
                set 6,(ix+3)    ;       bit bordo destro

                ld  hl,nsprt    ;       conta bordo DX
                inc (hl)
                ret



        
;***********************************************************
;
;   Sprite in coordinate reali dello schermo: 32 records
;
;                   b7 ,b6 ,b5 ,b4 ,b3 ,b2 ,b1 ,b0 
;   byte            ACT,0  ,0  ,0  [ sprite type ]
;   byte            [           status           ]
;   word            X
;   word            Y

REALXY  
   
    db  0,0
    dw  28*16,#90      ; Laser
    db  0,0
    DW  28*16,#A0
    db  0,0
    DW  28*16,#B0
    db  0,0
    DW  28*16,#C0

    db  0,0
    dw  33*16,#90      ; Laser
    db  0,0
    DW  33*16,#A0
    db  0,0
    DW  33*16,#B0
    db  0,0
    DW  33*16,#C0

    db  0,0
    dw  31*16,#90      ; Laser test
    db  0,0
    DW  31*16,#A0
    db  0,0
    DW  31*16,#B0
    db  0,0
    DW  31*16,#C0


    db  0,0
    dw  35*16,#90      ; Laser test
    db  0,0
    DW  35*16,#A0
    db  0,0
    DW  35*16,#B0
;    db  0,0
;    DW  35*16,#C0



    db  0,0
    DW  19*16,39*16
    db  0,0
    DW  22*16,39*16

    db  0,0
    dw  19*16,39*16     ; BLU
    db  0,0
    DW  65*16,57*16     ; BLU
    db  0,0
    DW  24*16,29*16     ; blu   

    db  0,0
    DW  56*16,27*16     ; PALLA
    db  0,0
    DW  58*16,26*16-4   ; PALLA
    db  0,0
    DW  46*16,13*16     ; PALLA

    db  0,0
    DW  21*16,51*16     ; COCC
    db  0,0
    DW  44*16,13*16     ; COCC
    db  0,0
    DW  48*16,13*16     ; COCC

    db  0,0
    DW  16,16     ; test

;*************************************************************



finish

    END

