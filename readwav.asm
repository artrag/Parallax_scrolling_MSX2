; ReadWave v1.0
; by Ricardo Bittencourt


BDOS    EQU 00005H
STROUT  EQU 00009H
FOPEN   EQU 0000FH
FCLOSE  EQU 00010H
RDSEQ   EQU 00014H
SETDTA  EQU 0001AH

START:
    LD  HL,082H
    LD  DE,FCB+1
START0:
    LD  A,(HL)
    CP  0DH
    JR  Z,START1
    LD  (DE),A
    INC HL
    INC DE
    JR  START0

; Open wave file

START1:
    LD  DE,FCB
    LD  C,FOPEN
    CALL    BDOS
    INC A
    JP      Z,ERROR1

    LD  DE,MSG2
    LD  C,STROUT
    CALL    BDOS

    LD  DE,BUFFER
    LD  HL,080H
    LD  IX,0
START2:
    PUSH    IX
    PUSH    DE
    PUSH    HL
    LD  C,SETDTA
    CALL    BDOS
    LD  DE,FCB
    LD  C,RDSEQ
    CALL    BDOS
    DEC A
    JR  Z,START3
    POP DE
    POP HL
    POP IX
    INC IX
    ADD HL,DE
    EX  DE,HL
    JR  START2

START3:
    POP DE
    POP HL
    POP IX
    ADD IX,IX
    ADD IX,IX
    ADD IX,IX
    ADD IX,IX
    ADD IX,IX
    ADD IX,IX
    ADD IX,IX
    LD  (TOTAL),IX
    LD  DE,FCB
    LD  C,FCLOSE
    CALL    BDOS

    LD  DE,MSG4
    LD  C,STROUT
    CALL    BDOS

; Wait for 2 second
; it's sufficient to stop the drive

    LD  B,120
WAIT:
    EI
    HALT
    DJNZ    WAIT

; Main loop

MAIN:
    DI
    LD  A,7
    OUT (0A0H),A
    IN  A,(0A2H)
    AND 11000000B
    OR  00111110B
    OUT (0A1H),A

    LD  A,0
    OUT (0A0H),A
    LD  A,0H
    OUT (0A1H),A

    LD  A,1
    OUT (0A0H),A
    LD  A,0H
    OUT (0A1H),A

    LD  A,8
    OUT (0A0H),A
    LD  A,0FH
    OUT (0A1H),A

    LD  HL,BUFFER+02CH
    LD  DE,0

MAIN0:
    IN  A,(0AAH)
    AND 0F0H
    OR  7
    OUT (0AAH),A
    IN  A,(0A9H)
    BIT 4,A
    JR  Z,EXIT

; synch delay
; must be adjusted by hand
; in a trial-and-error way
; this value was obtained for 11 kHz
    LD  B,10
MAIN1:  DJNZ    MAIN1

    LD  A,(HL)
    SRL A
    SRL A
    SRL A
    SRL A
    OUT (0A1H),A
    INC HL
    INC DE
    LD  A,(TOTAL+1)
    CP  D
    JR  NZ,MAIN0

    LD  HL,BUFFER+02CH
    LD  DE,0
    JR  MAIN0

EXIT:
    LD  A,7
    OUT (0A0H),A
    IN  A,(0A2H)
    AND 11000000B
    OR  00111111B
    OUT (0A1H),A
    EI
    JP  0

ERROR1:
    LD  DE,MSG1
    LD  C,STROUT
    CALL    BDOS
    RET

ERROR2:
    LD  DE,MSG3
    LD  C,STROUT
    CALL    BDOS
    RET

MSG1:   DB  'Cannot open file$'
MSG2:   DB  'Reading file...$'
MSG3:   DB  'Error reading file$'
MSG4:   DB  13,10,'Playing...$'

TOTAL:  DW  0

FCB:    DB  0
    DB  32,32,32,32
    DB  32,32,32,32
    DB  'WAV'
    DB  0,0,0,0,0,0,0,0,0,0,0
    DB  0,0,0,0,0,0,0,0,0,0,0
    DB  0,0,0,0,0,0,0,0,0,0,0
    DB  0,0,0,0,0,0,0,0,0,0,0

BUFFER:

    END     START


