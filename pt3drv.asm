    
    db  #fe
    dw  start
    dw  finish
    dw  autoexec

       ORG #C000
start
autoexec
         LD HL,SONG
         CALL INIT  ; initialize
WAIT:
         XOR A
         CALL #00D8 ; check space
         OR A       ; if pressed
         jr NZ,exit     ; than exit
         EI
         HALT       ; wait 1 intr.
         CALL PLAY  ; play 1 quark
         JR WAIT
exit:    CALL MUTE  ; silence
         RET


 
;Vortex Tracker II v1.0 PT3 player for MSX
;Adapted by Alfonso D. C. aka Dioniso <dioniso072@yahoo.es>
;26-Jan-05
;From:
;Vortex Tracker II v1.0 PT3 player for ZX Spectrum
;(c)2004 S.V.Bulba <vorobey@mail.khstu.ru> http://bulba.at.kz

;Release number
;Release: .equ '6'

;Features
;--------
;-Can be compiled at any address (i.e. no need rounding .org
; address).
;-Variables (VARS) can be located at any address (not only after
;code block).
;-INIT subroutine detects module version and rightly generates
; both note and volume tables outside of code block (in VARS).
;-Two portamento (spc. command 3xxx) algorithms (depending of
; module version).
;-Any Tempo value are accepted (including Tempo=1 and Tempo=2).
;-Fully compatible with Ay_Emul PT3 player codes.
;-See also notes at the end of this source code.

;Limitations
;-----------
;-Can run in RAM only (self-modified code is used).

;Warning!!! PLAY subroutine can crash if no module are loaded
;into RAM or INIT subroutine was not called before.

;Call MUTE or INIT one more time to mute sound after stopping
;playing 

;Entry and other points
;START initialization
;START+3 initialization with module address in HL
;START+5 play one quark
;START+8 mute
;START+10 setup and status flags
;START+11 pointer to current position value in PT3 module;
;After INIT (START+11) points to Postion0-1 (optimization)

START:
    LD HL,MDLADDR   ;Address of PT3 module
    JR INIT     ;START+3
    JP PLAY     ;START+5
    JR MUTE     ;START+8
SETUP:   db 0 ;set bit0 to 1, if you want to play without looping
         ;bit7 is set each time, when loop point is passed
CrPsPtr:     dw 0 

;Identifier
;   .db "=VTII PT3 Player r.",Release,"="

CHECKLP:    LD HL,SETUP
            SET 7,(HL)
            BIT 0,(HL)
            RET Z
            POP HL
            LD HL,DelyCnt
            INC (HL)
            LD HL,ChanA+CHNPRM_NtSkCn
            INC (HL)
MUTE:       LD A,(SETUP)
            AND %10000001
            LD (SETUP),A
            XOR A
            LD H,A
            LD L,A
            LD (AYREGS+AR_AmplA),A
            LD (AYREGS+AR_AmplB),HL
            JP ROUT_A0

INIT:
;HL - AddressOfModule

           LD (MODADDR),HL
           LD (MDADDR2),HL
           PUSH HL
           LD DE,100
           ADD HL,DE
           LD A,(HL)
           LD (Delay),A
           PUSH HL
           POP IX
           ADD HL,DE
           LD (CrPsPtr),HL
           LD E,(IX+102-100)
           ADD HL,DE
           INC HL
           LD (LPosPtr),HL
           POP DE
           LD L,(IX+103-100)
           LD H,(IX+104-100)
           ADD HL,DE
           LD (PatsPtr),HL
           LD HL,169
           ADD HL,DE
           LD (OrnPtrs),HL
           LD HL,105
           ADD HL,DE
           LD (SamPtrs),HL
           LD HL,SETUP
           RES 7,(HL)

;note table data depacker
           LD DE,T_PACK
           LD BC,T1_+(2*49)-1
TP_0:      LD A,(DE)
           INC DE
           CP 15*2
           JR NC,TP_1
           LD H,A
           LD A,(DE)
           LD L,A
           INC DE
           JR TP_2
TP_1:      PUSH DE
           LD D,0
           LD E,A
           ADD HL,DE
           ADD HL,DE
           POP DE
TP_2:      LD A,H
           LD (BC),A
           DEC BC
           LD A,L
           LD (BC),A
           DEC BC
           SUB #F0
           JR NZ,TP_0

           LD HL,VARS
           LD (HL),A
           LD DE,VARS+1
           LD BC,VAR0END-VARS-1
           LDIR
           INC A
           LD (DelyCnt),A
           LD HL,#F001 ;H - CHNPRM_Volume, L - CHNPRM_NtSkCn
           LD (ChanA+CHNPRM_NtSkCn),HL
           LD (ChanB+CHNPRM_NtSkCn),HL
           LD (ChanC+CHNPRM_NtSkCn),HL

           LD HL,EMPTYSAMORN
           LD (AdInPtA),HL ;ptr to zero
           LD (ChanA+CHNPRM_OrnPtr),HL ;ornament 0 is "0,1,0"
           LD (ChanB+CHNPRM_OrnPtr),HL ;in all versions from
           LD (ChanC+CHNPRM_OrnPtr),HL ;3.xx to 3.6x and VTII

           LD (ChanA+CHNPRM_SamPtr),HL ;S1 There is no default
           LD (ChanB+CHNPRM_SamPtr),HL ;S2 sample in PT3, so, you
           LD (ChanC+CHNPRM_SamPtr),HL ;S3 can comment S1,2,3; see
                           ;also EMPTYSAMORN comment

           LD A,(IX+13-100) ;EXTRACT VERSION NUMBER
           SUB #30
           JR C,L20
           CP 10
           JR C,L21
L20:       LD A,6
L21:       LD (Version),A
           PUSH AF
           CP 4
           LD A,(IX+99-100) ;TONE TABLE NUMBER
           RLA
           AND 7

;NoteTableCreator (c) Ivan Roshin
;A - NoteTableNumber*2+VersionForNoteTable
;(xx1b - 3.xx..3.4r, xx0b - 3.4x..3.6x..VTII1.0)

           LD HL,NT_DATA
           PUSH DE
           LD D,B
           ADD A,A
           LD E,A
           ADD HL,DE
           LD E,(HL)
           INC HL
           SRL E
           SBC A,A
           AND #A7 ;#00 (NOP) or #A7 (AND A)
           LD (L3),A
           EX DE,HL
           POP BC ;BC=T1_
           ADD HL,BC

           LD A,(DE)

           LD BC,T_
           ADD A,C
           LD C,A
           ADC A,B

           SUB C
           LD B,A
           PUSH BC
           LD DE,NT_
           PUSH DE

           LD B,12
L1:        PUSH BC
           LD C,(HL)
           INC HL
           PUSH HL
           LD B,(HL)

           PUSH DE
           EX DE,HL
           LD DE,23
           db #DD,#26,#08 ;LD XH,8

L2:        SRL B
           RR C
L3:        db #19 ;AND A or NOP
           LD A,C
           ADC A,D ;=ADC 0
           LD (HL),A
           INC HL
           LD A,B
           ADC A,D
           LD (HL),A
           ADD HL,DE
            db #DD,#25 ;DEC XH
           JR NZ,L2

           POP DE
           INC DE
           INC DE
           POP HL
           INC HL
           POP BC
           DJNZ L1

           POP HL
           POP DE

           LD A,E
           PUSH DE
           LD DE,TCOLD_1
           CP E
           POP DE
           JR NZ,CORR_1
           LD A,#FD
           LD (NT_+#2E),A
    
CORR_1:
           LD A,(DE)
           AND A
           JR Z,TC_EXIT
           RRA
           PUSH AF
           ADD A,A
           LD C,A
           ADD HL,BC
           POP AF
           JR NC,CORR_2
           DEC (HL)
           DEC (HL)
CORR_2:    INC (HL)
    AND A
    SBC HL,BC
    INC DE
    JR CORR_1

TC_EXIT:

    POP AF

;VolTableCreator (c) Ivan Roshin
;A - VersionForVolumeTable (0..4 - 3.xx..3.4x;
               ;5.. - 3.5x..3.6x..VTII1.0)

    CP 5
    LD HL,#11
    LD D,H
    LD E,H
    LD A,#17
    JR NC,M1
    DEC L
    LD E,L
    XOR A
M1:      LD (M2),A

    LD IX,VT_+16
    LD C,#10

INITV2:  PUSH HL

    ADD HL,DE
    EX DE,HL
    SBC HL,HL

INITV1:  LD A,L
M2:       db #7D
    LD A,H
    ADC A,0
    LD (IX),A
    INC IX
    ADD HL,DE
    INC C
    LD A,C
    AND 15
    JR NZ,INITV1

    POP HL
    LD A,E
    CP #77
    JR NZ,M3
    INC E
M3:      LD A,C
    AND A
    JR NZ,INITV2

    JP ROUT_A0

;pattern decoder
PD_OrSm:    LD (IX-12+CHNPRM_Env_En),0
    CALL SETORN
    LD A,(BC)
    INC BC
    RRCA

PD_SAM: ADD A,A
PD_SAM_:    LD E,A
    LD D,0
SamPtrs:  equ $+1
    LD HL,#2121
    ADD HL,DE
    LD E,(HL)
    INC HL
    LD D,(HL)
MODADDR:  equ $+1
    LD HL,#2121
    ADD HL,DE
    LD (IX-12+CHNPRM_SamPtr),L
    LD (IX-12+CHNPRM_SamPtr+1),H
    JR PD_LOOP

PD_VOL: RLCA
    RLCA
    RLCA
    RLCA
    LD (IX-12+CHNPRM_Volume),A
    JR PD_LP2
    
PD_EOff:    LD (IX-12+CHNPRM_Env_En),A
    LD (IX-12+CHNPRM_PsInOr),A
    JR PD_LP2

PD_SorE:    DEC A
    JR NZ,PD_ENV
    LD A,(BC)
    INC BC
    LD (IX-12+CHNPRM_NNtSkp),A
    JR PD_LP2

PD_ENV: CALL SETENV
    JR PD_LP2

PD_ORN: CALL SETORN
    JR PD_LOOP
       
PD_ESAM:    LD (IX-12+CHNPRM_Env_En),A
    LD (IX-12+CHNPRM_PsInOr),A
    CALL NZ,SETENV
    LD A,(BC)
    INC BC
    JR PD_SAM_

PTDECOD: LD A,(IX-12+CHNPRM_Note)
    LD (PrNote+1),A
    LD L,(IX-12+CHNPRM_CrTnSl)
    LD H,(IX-12+CHNPRM_CrTnSl+1)
    LD (PrSlide+1),HL

PD_LOOP:    LD DE,#2010
PD_LP2: LD A,(BC)
    INC BC
    ADD A,E
    JR C,PD_OrSm
    ADD A,D
    JR Z,PD_FIN
    JR C,PD_SAM
    ADD A,E
    JR Z,PD_REL
    JR C,PD_VOL
    ADD A,E
    JR Z,PD_EOff
    JR C,PD_SorE
    ADD A,96
    JR C,PD_NOTE
    ADD A,E
    JR C,PD_ORN
    ADD A,D
    JR C,PD_NOIS
    ADD A,E
    JR C,PD_ESAM
    ADD A,A
    LD E,A
    
    PUSH DE
    LD DE,#DF20
    LD HL,SPCCOMS   
    ADD HL,DE
    POP DE
    
    ADD HL,DE
    LD E,(HL)
    INC HL
    LD D,(HL)
    PUSH DE
    JR PD_LOOP

PD_NOIS:    LD (Ns_Base),A
    JR PD_LP2

PD_REL: RES 0,(IX-12+CHNPRM_Flags)
    JR PD_RES
    
PD_NOTE:    LD (IX-12+CHNPRM_Note),A
    SET 0,(IX-12+CHNPRM_Flags)
    XOR A

PD_RES: LD (PDSP_+1),SP
    LD SP,IX
    LD H,A
    LD L,A
    PUSH HL
    PUSH HL
    PUSH HL
    PUSH HL
    PUSH HL
    PUSH HL
PDSP_:  LD SP,#3131

PD_FIN: LD A,(IX-12+CHNPRM_NNtSkp)
    LD (IX-12+CHNPRM_NtSkCn),A
    RET

C_PORTM: RES 2,(IX-12+CHNPRM_Flags)
    LD A,(BC)
    INC BC
;SKIP PRECALCULATED TONE DELTA (BECAUSE
;CANNOT BE RIGHT AFTER PT3 COMPILATION)
    INC BC
    INC BC
    LD (IX-12+CHNPRM_TnSlDl),A
    LD (IX-12+CHNPRM_TSlCnt),A
    LD DE,NT_
    LD A,(IX-12+CHNPRM_Note)
    LD (IX-12+CHNPRM_SlToNt),A
    ADD A,A
    LD L,A
    LD H,0
    ADD HL,DE
    LD A,(HL)
    INC HL
    LD H,(HL)
    LD L,A
    PUSH HL
PrNote: LD A,#3E
    LD (IX-12+CHNPRM_Note),A
    ADD A,A
    LD L,A
    LD H,0
    ADD HL,DE
    LD E,(HL)
    INC HL
    LD D,(HL)
    POP HL
    SBC HL,DE
    LD (IX-12+CHNPRM_TnDelt),L
    LD (IX-12+CHNPRM_TnDelt+1),H
    LD E,(IX-12+CHNPRM_CrTnSl)
    LD D,(IX-12+CHNPRM_CrTnSl+1)
Version:  equ $+1
    LD A,#3E
    CP 6
    JR C,OLDPRTM ;Old 3xxx for PT v3.5-
PrSlide:    LD DE,#1111
    LD (IX-12+CHNPRM_CrTnSl),E
    LD (IX-12+CHNPRM_CrTnSl+1),D
OLDPRTM:    LD A,(BC) ;SIGNED TONE STEP
    INC BC
    EX AF,AF'
    LD A,(BC)
    INC BC
    AND A
    JR Z,NOSIG
    EX DE,HL
NOSIG:  SBC HL,DE
    JP P,SET_STP
    CPL
    EX AF,AF'
    NEG
    EX AF,AF'
SET_STP:    LD (IX-12+CHNPRM_TSlStp+1),A
    EX AF,AF'
    LD (IX-12+CHNPRM_TSlStp),A
    LD (IX-12+CHNPRM_COnOff),0
    RET

C_GLISS:    SET 2,(IX-12+CHNPRM_Flags)
    LD A,(BC)
    INC BC
    LD (IX-12+CHNPRM_TnSlDl),A
    LD (IX-12+CHNPRM_TSlCnt),A
    LD A,(BC)
    INC BC
    EX AF,AF'
    LD A,(BC)
    INC BC
    JR SET_STP

C_SMPOS:    LD A,(BC)
    INC BC
    LD (IX-12+CHNPRM_PsInSm),A
    RET

C_ORPOS:    LD A,(BC)
    INC BC
    LD (IX-12+CHNPRM_PsInOr),A
    RET

C_VIBRT:    LD A,(BC)
    INC BC
    LD (IX-12+CHNPRM_OnOffD),A
    LD (IX-12+CHNPRM_COnOff),A
    LD A,(BC)
    INC BC
    LD (IX-12+CHNPRM_OffOnD),A
    XOR A
    LD (IX-12+CHNPRM_TSlCnt),A
    LD (IX-12+CHNPRM_CrTnSl),A
    LD (IX-12+CHNPRM_CrTnSl+1),A
    RET

C_ENGLS:    LD A,(BC)
    INC BC
    LD (Env_Del),A
    LD (CurEDel),A
    LD A,(BC)
    INC BC
    LD L,A
    LD A,(BC)
    INC BC
    LD H,A
    LD (ESldAdd),HL
    RET

C_DELAY:    LD A,(BC)
    INC BC
    LD (Delay),A
    RET
    
SETENV: LD (IX-12+CHNPRM_Env_En),E
    LD (AYREGS+AR_EnvTp),A
    LD A,(BC)
    INC BC
    LD H,A
    LD A,(BC)
    INC BC
    LD L,A
    LD (EnvBase),HL
    XOR A
    LD (IX-12+CHNPRM_PsInOr),A
    LD (CurEDel),A
    LD H,A
    LD L,A
    LD (CurESld),HL
C_NOP:  RET

SETORN: ADD A,A
    LD E,A
    LD D,0
    LD (IX-12+CHNPRM_PsInOr),D
OrnPtrs:     equ $+1
    LD HL,#2121
    ADD HL,DE
    LD E,(HL)
    INC HL
    LD D,(HL)
MDADDR2:     equ $+1
    LD HL,#2121
    ADD HL,DE
    LD (IX-12+CHNPRM_OrnPtr),L
    LD (IX-12+CHNPRM_OrnPtr+1),H
    RET

;ALL 16 ADDRESSES TO PROTECT FROM BROKEN PT3 MODULES
SPCCOMS:  dw C_NOP
     dw C_GLISS
     dw C_PORTM
     dw C_SMPOS
     dw C_ORPOS
     dw C_VIBRT
     dw C_NOP
     dw C_NOP
     dw C_ENGLS
     dw C_DELAY
     dw C_NOP
     dw C_NOP
     dw C_NOP
     dw C_NOP
     dw C_NOP
     dw C_NOP

CHREGS: XOR A
    LD (Ampl),A
    BIT 0,(IX+CHNPRM_Flags)
    PUSH HL
    JP Z,CH_EXIT
    LD (CSP_+1),SP
    LD L,(IX+CHNPRM_OrnPtr)
    LD H,(IX+CHNPRM_OrnPtr+1)
    LD SP,HL
    POP DE
    LD H,A
    LD A,(IX+CHNPRM_PsInOr)
    LD L,A
    ADD HL,SP
    INC A
    CP D
    JR C,CH_ORPS
    LD A,E
CH_ORPS:    LD (IX+CHNPRM_PsInOr),A
    LD A,(IX+CHNPRM_Note)
    ADD A,(HL)
    JP P,CH_NTP
    XOR A
CH_NTP: CP 96
    JR C,CH_NOK
    LD A,95
CH_NOK: ADD A,A
    EX AF,AF'
    LD L,(IX+CHNPRM_SamPtr)
    LD H,(IX+CHNPRM_SamPtr+1)
    LD SP,HL
    POP DE
    LD H,0
    LD A,(IX+CHNPRM_PsInSm)
    LD B,A
    ADD A,A
    ADD A,A
    LD L,A
    ADD HL,SP
    LD SP,HL
    LD A,B
    INC A
    CP D
    JR C,CH_SMPS
    LD A,E
CH_SMPS:    LD (IX+CHNPRM_PsInSm),A
    POP BC
    POP HL
    LD E,(IX+CHNPRM_TnAcc)
    LD D,(IX+CHNPRM_TnAcc+1)
    ADD HL,DE
    BIT 6,B
    JR Z,CH_NOAC
    LD (IX+CHNPRM_TnAcc),L
    LD (IX+CHNPRM_TnAcc+1),H
CH_NOAC: EX DE,HL
    EX AF,AF'
    LD L,A
    LD H,0
    LD SP,NT_
    ADD HL,SP
    LD SP,HL
    POP HL
    ADD HL,DE
    LD E,(IX+CHNPRM_CrTnSl)
    LD D,(IX+CHNPRM_CrTnSl+1)
    ADD HL,DE
CSP_:   LD SP,#3131
    EX (SP),HL
    XOR A
    OR (IX+CHNPRM_TSlCnt)
    JR Z,CH_AMP
    DEC (IX+CHNPRM_TSlCnt)
    JR NZ,CH_AMP
    LD A,(IX+CHNPRM_TnSlDl)
    LD (IX+CHNPRM_TSlCnt),A
    LD L,(IX+CHNPRM_TSlStp)
    LD H,(IX+CHNPRM_TSlStp+1)
    LD A,H
    ADD HL,DE
    LD (IX+CHNPRM_CrTnSl),L
    LD (IX+CHNPRM_CrTnSl+1),H
    BIT 2,(IX+CHNPRM_Flags)
    JR NZ,CH_AMP
    LD E,(IX+CHNPRM_TnDelt)
    LD D,(IX+CHNPRM_TnDelt+1)
    AND A
    JR Z,CH_STPP
    EX DE,HL
CH_STPP: SBC HL,DE
    JP M,CH_AMP
    LD A,(IX+CHNPRM_SlToNt)
    LD (IX+CHNPRM_Note),A
    XOR A
    LD (IX+CHNPRM_TSlCnt),A
    LD (IX+CHNPRM_CrTnSl),A
    LD (IX+CHNPRM_CrTnSl+1),A
CH_AMP: LD A,(IX+CHNPRM_CrAmSl)
    BIT 7,C
    JR Z,CH_NOAM
    BIT 6,C
    JR Z,CH_AMIN
    CP 15
    JR Z,CH_NOAM
    INC A
    JR CH_SVAM
CH_AMIN:    CP -15
    JR Z,CH_NOAM
    DEC A
CH_SVAM:    LD (IX+CHNPRM_CrAmSl),A
CH_NOAM:    LD L,A
    LD A,B
    AND 15
    ADD A,L
    JP P,CH_APOS
    XOR A
CH_APOS:    CP 16
    JR C,CH_VOL
    LD A,15
CH_VOL: OR (IX+CHNPRM_Volume)
    LD L,A
    LD H,0
    LD DE,VT_
    ADD HL,DE
    LD A,(HL)
CH_ENV: BIT 0,C
    JR NZ,CH_NOEN
    OR (IX+CHNPRM_Env_En)
CH_NOEN:    LD (Ampl),A
    BIT 7,B
    LD A,C
    JR Z,NO_ENSL
    RLA
    RLA
    SRA A
    SRA A
    SRA A
    ADD A,(IX+CHNPRM_CrEnSl) ;SEE COMMENT BELOW
    BIT 5,B
    JR Z,NO_ENAC
    LD (IX+CHNPRM_CrEnSl),A
NO_ENAC:    LD HL,AddToEn
    ADD A,(HL) ;BUG IN PT3 - NEED WORD HERE.
           ;FIX IT IN NEXT VERSION?
    LD (HL),A
    JR CH_MIX
NO_ENSL: RRA
    ADD A,(IX+CHNPRM_CrNsSl)
    LD (AddToNs),A
    BIT 5,B
    JR Z,CH_MIX
    LD (IX+CHNPRM_CrNsSl),A
CH_MIX: LD A,B
    RRA
    AND #48
CH_EXIT:    LD HL,AYREGS+AR_Mixer
    OR (HL)
    RRCA
    LD (HL),A
    POP HL
    XOR A
    OR (IX+CHNPRM_COnOff)
    RET Z
    DEC (IX+CHNPRM_COnOff)
    RET NZ
    XOR (IX+CHNPRM_Flags)
    LD (IX+CHNPRM_Flags),A
    RRA
    LD A,(IX+CHNPRM_OnOffD)
    JR C,CH_ONDL
    LD A,(IX+CHNPRM_OffOnD)
CH_ONDL:    LD (IX+CHNPRM_COnOff),A
    RET

PLAY:    XOR A
    LD (AddToEn),A
    LD (AYREGS+AR_Mixer),A
    DEC A
    LD (AYREGS+AR_EnvTp),A
    LD HL,DelyCnt
    DEC (HL)
    JR NZ,PL2
    LD HL,ChanA+CHNPRM_NtSkCn
    DEC (HL)
    JR NZ,PL1B
AdInPtA:     equ $+1
    LD BC,#0101
    LD A,(BC)
    AND A
    JR NZ,PL1A
    LD D,A
    LD (Ns_Base),A
    LD HL,(CrPsPtr)
    INC HL
    LD A,(HL)
    INC A
    JR NZ,PLNLP
    CALL CHECKLP
LPosPtr:     equ $+1
    LD HL,#2121
    LD A,(HL)
    INC A
PLNLP:  LD (CrPsPtr),HL
    DEC A
    ADD A,A
    LD E,A
    RL D
PatsPtr:     equ $+1
    LD HL,#2121
    ADD HL,DE
    LD DE,(MODADDR)
    LD (PSP_+1),SP
    LD SP,HL
    POP HL
    ADD HL,DE
    LD B,H
    LD C,L
    POP HL
    ADD HL,DE
    LD (AdInPtB),HL
    POP HL
    ADD HL,DE
    LD (AdInPtC),HL
PSP_:   LD SP,#3131
PL1A:   LD IX,ChanA+12
    CALL PTDECOD
    LD (AdInPtA),BC

PL1B:   LD HL,ChanB+CHNPRM_NtSkCn
    DEC (HL)
    JR NZ,PL1C
    LD IX,ChanB+12
AdInPtB:     equ $+1
    LD BC,#0101
    CALL PTDECOD
    LD (AdInPtB),BC

PL1C:   LD HL,ChanC+CHNPRM_NtSkCn
    DEC (HL)
    JR NZ,PL1D
    LD IX,ChanC+12
AdInPtC:     equ $+1
    LD BC,#0101
    CALL PTDECOD
    LD (AdInPtC),BC

Delay:   equ $+1
PL1D:   LD A,#3E
    LD (DelyCnt),A

PL2:    LD IX,ChanA
    LD HL,(AYREGS+AR_TonA)
    CALL CHREGS
    LD (AYREGS+AR_TonA),HL
    LD A,(Ampl)
    LD (AYREGS+AR_AmplA),A
    LD IX,ChanB
    LD HL,(AYREGS+AR_TonB)
    CALL CHREGS
    LD (AYREGS+AR_TonB),HL
    LD A,(Ampl)
    LD (AYREGS+AR_AmplB),A
    LD IX,ChanC
    LD HL,(AYREGS+AR_TonC)
    CALL CHREGS
;   LD A,(Ampl) ;Ampl = AYREGS+AR_AmplC
;   LD (AYREGS+AR_AmplC),A
    LD (AYREGS+AR_TonC),HL

    LD HL,(Ns_Base_AddToNs)
    LD A,H
    ADD A,L
    LD (AYREGS+AR_Noise),A

AddToEn:  equ $+1
    LD A,#3E
    LD E,A
    ADD A,A
    SBC A,A
    LD D,A
    LD HL,(EnvBase)
    ADD HL,DE
    LD DE,(CurESld)
    ADD HL,DE
    LD (AYREGS+AR_Env),HL

    XOR A
    LD HL,CurEDel
    OR (HL)
    JR Z,ROUT_A0
    DEC (HL)
    JR NZ,ROUT
Env_Del:     equ $+1
    LD A,#3E
    LD (HL),A
ESldAdd:     equ $+1
    LD HL,#2121
    ADD HL,DE
    LD (CurESld),HL

ROUT:   XOR A
ROUT_A0:
    LD C,#A0
    LD HL,AYREGS
LOUT:   OUT (C),A
    INC C
    OUTI 
    DEC C
    INC A
    CP 8
    JR NZ,LOUT
    OUT (#A0),A
    LD A,(SETUP)
    AND %00000010
    JR Z,R08_
    XOR A
    OUT (#A1),A
    JR R09
R08_
    LD A,(HL)
    OUT (#A1),A
R09:
    LD A,9
    INC HL
    OUT (#A0),A
    LD A,(SETUP)
    AND %00000100
    JR Z,R09_
    XOR A
    OUT (#A1),A
    JR R10
R09_:
    LD A,(HL)
    OUT (#A1),A
R10:
    LD A,10
    INC HL
    OUT (#A0),A
    LD A,(SETUP)
    AND %00001000
    JR Z,R10_
    XOR A
    OUT (#A1),A
    JR R11
R10_:
    LD A,(HL)
    OUT (#A1),A
R11:
    LD A,11
    INC HL
    OUT (#A0),A
    LD A,(HL)
    OUT (#A1),A
    LD A,12
    INC HL
    OUT (#A0),A
    LD A,(HL)
    OUT (#A1),A
    LD A,13
    INC HL
    OUT (#A0),A
    LD A,(HL)
    AND A
    RET M
    OUT (#A1),A
    RET

NT_DATA:     db (T_NEW_0-T1_)*2
     db TCNEW_0-T_
     db (T_OLD_0-T1_)*2+1
     db TCOLD_0-T_
     db (T_NEW_1-T1_)*2+1
     db TCNEW_1-T_
     db (T_OLD_1-T1_)*2+1
     db TCOLD_1-T_
     db (T_NEW_2-T1_)*2
     db TCNEW_2-T_
     db (T_OLD_2-T1_)*2
     db TCOLD_2-T_
     db (T_NEW_3-T1_)*2
     db TCNEW_3-T_
     db (T_OLD_3-T1_)*2
     db TCOLD_3-T_

T_:

TCOLD_0:     db #00+1,#04+1,#08+1,#0A+1,#0C+1,#0E+1,#12+1,#14+1
     db #18+1,#24+1,#3C+1,0
TCOLD_1:     db #5C+1,0
TCOLD_2:     db #30+1,#36+1,#4C+1,#52+1,#5E+1,#70+1,#82,#8C,#9C
     db #9E,#A0,#A6,#A8,#AA,#AC,#AE,#AE,0
TCNEW_3:     db #56+1
TCOLD_3:     db #1E+1,#22+1,#24+1,#28+1,#2C+1,#2E+1,#32+1,#BE+1,0
TCNEW_0:     db #1C+1,#20+1,#22+1,#26+1,#2A+1,#2C+1,#30+1,#54+1
     db #BC+1,#BE+1,0
TCNEW_1:  equ TCOLD_1
TCNEW_2:     db #1A+1,#20+1,#24+1,#28+1,#2A+1,#3A+1,#4C+1,#5E+1
     db #BA+1,#BC+1,#BE+1,0

EMPTYSAMORN:  equ $-1
     db 1,0,#90 ;delete #90 if you don't need default sample

;first 12 values of tone tables (packed)

T_PACK: db #0d,#d8,#69,#70,#76,#7d,#85,#8d,#95,#9d,#a8,#b1,#bb,#0c,#da,#62
        db #68,#6d,#75,#7b,#83,#8a,#92,#9c,#a4,#af,#b8,#0e,#08,#6a,#72,#78
        db #7e,#86,#90,#96,#a0,#aa,#b4,#be,#0f,#c0,#78,#88,#80,#90,#98,#a0
        db #b0,#a8,#e0,#b0,#e8

;vars from here can be stripped
;you can move VARS to any other address

VARS:

;ChannelsVars
;struc  CHNPRM
;reset group
CHNPRM_PsInOr:   equ 0  ;RESB 1
CHNPRM_PsInSm:   equ 1  ;RESB 1
CHNPRM_CrAmSl:   equ 2  ;RESB 1
CHNPRM_CrNsSl:   equ 3  ;RESB 1
CHNPRM_CrEnSl:   equ 4  ;RESB 1
CHNPRM_TSlCnt:   equ 5  ;RESB 1
CHNPRM_CrTnSl:   equ 6  ;RESW 1
CHNPRM_TnAcc:    equ 8  ;RESW 1
CHNPRM_COnOff:   equ 10 ;RESB 1
;reset group

CHNPRM_OnOffD:   equ 11 ;RESB 1

;IX for PTDECOD here (+12)
CHNPRM_OffOnD:   equ 12 ;RESB 1
CHNPRM_OrnPtr:   equ 13 ;RESW 1
CHNPRM_SamPtr:   equ 15 ;RESW 1
CHNPRM_NNtSkp:   equ 17 ;RESB 1
CHNPRM_Note:     equ 18 ;RESB 1
CHNPRM_SlToNt:   equ 19 ;RESB 1
CHNPRM_Env_En:   equ 20 ;RESB 1
CHNPRM_Flags:    equ 21 ;RESB 1
 ;Enabled - 0,SimpleGliss - 2
CHNPRM_TnSlDl:   equ 22 ;RESB 1
CHNPRM_TSlStp:   equ 23 ;RESW 1
CHNPRM_TnDelt:   equ 25 ;RESW 1
CHNPRM_NtSkCn:   equ 27 ;RESB 1
CHNPRM_Volume:   equ 28 ;RESB 1
CHNPRM_Size  equ 29 ;RESB 1
;endstruc

ChanA:   ds CHNPRM_Size
ChanB:   ds CHNPRM_Size
ChanC:   ds CHNPRM_Size

;struc  AR
AR_TonA:     equ 0  ;RESW 1
AR_TonB:     equ 2  ;RESW 1
AR_TonC:     equ 4  ;RESW 1
AR_Noise:    equ 6  ;RESB 1
AR_Mixer:    equ 7  ;RESB 1
AR_AmplA:    equ 8  ;RESB 1
AR_AmplB:    equ 9  ;RESB 1
AR_AmplC:    equ 10 ;RESB 1
AR_Env:  equ 11 ;RESW 1
AR_EnvTp:    equ 13 ;RESB 1
;endstruc

;GlobalVars
DelyCnt:     db 0
CurESld:     dw 0
CurEDel:     db 0
Ns_Base_AddToNs:
Ns_Base:     db 0
AddToNs:     db 0

AYREGS:

VT_:     ds 256 ;CreatedVolumeTableAddress

EnvBase:     equ VT_+14

T1_:     equ VT_+16 ;Tone tables data depacked here

T_OLD_1:     equ T1_
T_OLD_2:     equ T_OLD_1+24
T_OLD_3:     equ T_OLD_2+24
T_OLD_0:     equ T_OLD_3+2
T_NEW_0:     equ T_OLD_0
T_NEW_1:     equ T_OLD_1
T_NEW_2:     equ T_NEW_0+24
T_NEW_3:     equ T_OLD_3

NT_:     ds 192 ;CreatedNoteTableAddress

;local var
Ampl:    equ AYREGS+AR_AmplC

VAR0END:     equ VT_+16 ;INIT zeroes from VARS to VAR0END-1

VARSEND:  equ $

MDLADDR:  equ $     ;Place your song here.

    INCLUDE "OLDSKOOL.GEN"


;Notes:
;Pro Tracker 3.4r can not be detected by header, so PT3.4r tone
;tables realy used only for modules of 3.3 and older versions.


finish

    END

YSORG  db  #00,#02
XDEST  
