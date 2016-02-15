levelcolors:
           db  #00,#00
           db  #02,#01
           db  #06,#00
           db  #07,#03
           db  #17,#01
           db  #53,#00
           db  #54,#01
           db  #64,#00
           db  #70,#05
           db  #70,#06
           db  #70,#07
           db  #67,#07
           db  #05,#04
           db  #03,#02
           db  #56,#05
           db  #77,#07

SetPalet:   
            xor a ;Set p#pointer to zero.
            vdp 16
            
            ld  hl,levelcolors
            ld c,vdpport2
            rept 32
            OUTI
            endm

            ret
