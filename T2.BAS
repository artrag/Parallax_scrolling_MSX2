   10  SCREEN 5,2
   20  DEFINT A-Z
   70  '
   90  vdp(10)=2:vdp(9)=vdp(9) or 2^5:'vdp(9)=vdp(9) xor 2^5
   94  '
   95  set page 3,3
   100  COLOR =(0,0,0,0):COLOR =(1,0,1,2):COLOR =(2,0,0,6):COLOR=(3,0,3,7)
   140  COLOR =(4,1,1,7):COLOR =(5,5,0,3):COLOR =(6,5,1,4):COLOR=(7,6,0,4)
   180  COLOR =(8,7,5,0):COLOR =(9,7,6,0):COLOR =(10,7,7,0):COLOR=(11,6,7,7)
   220  COLOR =(12,0,4,5):COLOR=(13,0,2,3):COLOR =(14,5,5,6):COLOR=(15,7,7,7)
   230  '
   240  set page 0,0
   250  'for n=0 to 63: sprite$(n)=string$(32,&b10101010):next
   270  '
   280 '_MBPLAY
   290 Bload"for2.out",r
   300 '_MBSTOP
   350 _system
  
