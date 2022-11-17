REM CLDHEX.BAS ver 0.1
REM Class CLDHEX for MachiKania Type P
REM for loading Intel HEX file to RAM

REM Intel HEX format example
REM :040bf000ffffffcf35
REM    +--------------------- Byte count
REM    |    +---------------- Address
REM    |    |  +------------- Record type (00:Data, 01:EOF, 04: Extended linear addres, 05: Start Linear Address)
REM    |    |  |        +---- Data
REM    |    |  |        |  +- Checksum
REM    |    |  |        |  |
REM : 04 0bf0 00 ffffffcf 35
REM : 02 0000 04     2001 D9

field public SLADDR
field private CAREA

method INIT
  var t,c,a,y,d,s,i,e
  if (args(0)<3) then goto ARGERR
  
  rem Reserve the area
  dim d(0)
  if args(2)<d then goto DIMERR
  dim d((args(2)-d)/4-1),CAREA((args(3)+3)/4-1)
  delete d
  if args(2)!=CAREA then goto DIMERR
  
  rem Open the HEX file
  if 0=fopen(ARGS$(1),"r") then goto FERR
  do until feof()
    t$=finput$()
    if peek(t)!=0x3a then goto ERR
    c=gosub(RDHEX,t+1,2)
    a=gosub(RDHEX,t+3,4)
    y=gosub(RDHEX,t+7,2)
    s=c+a+(a>>8)+y+gosub(RDHEX,t+9+c*2,2)
    if 0=y then
      a=e+a
      i=9
      do while c
        poke a,gosub(RDHEX,t+i,2)
        s=s+peek(a)
        a=a+1
        c=c-1
        i=i+2
      loop
    elseif 1=y then
      break
    elseif 4=y then
      e=gosub(RDHEX,t+9,c*2)<<16
      i=9
      do while c
        s=s+gosub(RDHEX,t+i,2)
        c=c-1
        i=i+2
      loop    
    elseif 5=y then
      SLADDR=gosub(RDHEX,t+9,c*2)
      i=9
      do while c
        s=s+gosub(RDHEX,t+i,2)
        c=c-1
        i=i+2
      loop    
    else
      goto ERR
    endif
    if s and 255 then goto CSERR
  loop
  fclose
return

label RDHEX
  var t,r,n,c
  t=args(1)
  n=args(2)
  r=0
  do while n
    n=n-1
    c=peek(t)
    t=t+1
    if c<0x3A then
      REM 0-9
      c=c-0x30
    elseif c<0x47 then
      REM A-F
      c=c-0x37
    else
      REM a-f
      c=c-0x57
    endif
    r=(r<<4)+c
  loop
return r

label ARGERR
  print "Arguments: hexfile, start-address, length"
  end
label DIMERR
  print "Area cannot be reserved"
  end
label ERR
  print "HEX file syntax error"
  end
label CSERR
  print "Checksum error"
  end
label FERR
  print "File error"
  end
