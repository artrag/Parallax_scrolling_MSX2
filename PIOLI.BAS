   10  SCREEN5,2:color ,0,0
   20  SETPAGE 2,2:cls:BLOAD"blk3.sr5",S
   30  for x=0 to3: copy (x*8,9*16)-(x*8+7,9*16+4) to (0,9*16+x*4):next
   40  line (4*16,5*16)-(&hd*16+15,9*16+15),0,bf
   50  line (8,9*16)-(&hd*16+15,9*16+15),0,bf
   60  bsave"blk4.sr5",0,128*256-1,s 
