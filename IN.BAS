   10  SCREEN5,2:color ,0,0
   20  SETPAGE 2,2:cls:BLOAD"blk4.sr5",S
   30  SETPAGE 3,3:cls:BLOAD"px.sr5",S
   40  'BLOAD"totalmus.bin",R:_MBMLOAD("total1.mbm")
   50  POKE&HC000,0:POKE&HF677,&HC0:RUN"t1.bas
