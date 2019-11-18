REM CKNJ12.BAS ver 0.3.1
REM Class CKNJ12 for MachiKania Type Z/M
REM using Shinonome 12x12 font

STATIC PRIVATE MODE,FBUFF,FO,PLT,BMPF

METHOD INIT
  REM File buffer size is 18 bytes
  dim FBUFF(4)
  REM 12x12 bytes matrix for PUTBMP
  dim BMPF(35)
  REM Set encoding
  REM MODE: either "EUC-JP", or "UTF-8"
  if 0<args(0) then
    if 0=STRNCMP("EUC-JP",args$(1),7) then
      MODE=1
    elseif 0=STRNCMP("UTF-8",args$(1),6) then
      MODE=2
    else
      print "Illegal encoding:";args$(1)
      end
    endif
  else
    REM Default: EUC-JP
    MODE=1
  endif
  return

METHOD GPRT
  var t$,b,i,j
  fclose
  FO=0
  REM Set palette
  PLT=args(2)*256+args(3)
  gosub GPSTR,args$(1)
  fclose
  return

REM Private method GPRTCH
REM 1st param: JIS code #
LABEL GPRTCH
  var i,x,y
  REM Create BMP from font file
  gosub FGETCH,args(1)
  if args(1)<0x100 then
    REM Half sized font
    goto GPRTHS
  endif
  for y=0 to 5
    i=peek(FBUFF+y*3)
    for x=0 to 7
      if i and (1<<(7-x)) then
        poke BMPF+y*24+x,PLT>>8
      else
        poke BMPF+y*24+x,PLT and 0xff
      endif
    next
    i=peek(FBUFF+y*3+1)
    for x=8 to 11
      if i and (1<<(15-x)) then
        poke BMPF+y*24+x,PLT>>8
      else
        poke BMPF+y*24+x,PLT and 0xff
      endif
    next
    for x=0 to 3
      if i and (1<<(3-x)) then
        poke BMPF+(y*2+1)*12+x,PLT>>8
      else
        poke BMPF+(y*2+1)*12+x,PLT and 0xff
      endif
    next
    i=peek(FBUFF+y*3+2)
    for x=4 to 11
      if i and (1<<(11-x)) then
        poke BMPF+(y*2+1)*12+x,PLT>>8
      else
        poke BMPF+(y*2+1)*12+x,PLT and 0xff
      endif
    next
  next
  REM Draw in graphic
  x=SYSTEM(28)
  y=SYSTEM(29)
  if SYSTEM(22)<x+12 then
    x=0
    y=y+12
    point x,y
  endif
  putbmp x,y,12,12,BMPF
  point x+12,y
  return

LABEL GPRTHS
  for y=0 to 11
    i=peek(FBUFF+y)
    for x=0 to 5
      if i and (1<<(7-x)) then
        poke BMPF+y*6+x,PLT>>8
      else
        poke BMPF+y*6+x,PLT and 0xff
      endif
    next
  next
  REM Draw in graphic
  x=SYSTEM(28)
  y=SYSTEM(29)
  if SYSTEM(22)<x+6 then
    x=0
    y=y+12
    point x,y
  endif
  putbmp x,y,6,12,BMPF
  point x+6,y
  return

REM Private method FOP
REM 1st param: file name
LABEL FOP
  var t
  REM Try current directory
  if fopen(args$(1),"r") then return
  REM Try library directory
  t$=getdir$()
  setdir "\\LIB\\CKNJ12"
  fopen args$(1),"r"
  setdir t$
  delete t
  return

REM Private medthod FGETCH
REM 1st param: JIS code #
LABEL FGETCH
  var p
  if 0=FO then
    REM File isn't yet open
    REM open it 
    FO=1
    if 2=MODE then
      gosub FOP,"SHNMK12.UNI"
    else
      gosub FOP,"SHNMK12.JIS"
    endif
  endif
  p=args(1)
  if 0x20<=p and p<=0x7f then
    REM 7 bits half size font
    fseek (p-0x20)*12
    fget FBUFF,12
    return
  endif
  if 2=MODE then
    REM UTF-8
    if p<0x0500 then
      p=p-0x500
    elseif p<0x2000 then
      REM ERR
      p=-1
    elseif p<0x2700 then
      p=p-0x2000+0x0500
    elseif p<0x3000 then
      p=-1
    elseif p<0x3100 then
      p=p-0x3000+0x0c00
    elseif p<0x4e00 then
      p=-1
    elseif p<0xa000 then
      p=p-0x4e00+0x0d00
    elseif p<0xff00 then
      p=-1
    else
      p=p-0xff00+0x5f00
    endif
  else
    REM EUC
    p=p-0xa1a1
  endif
  p=p*18+1152
  if 0<=p and p+18<flen() then
    fseek p
    fget FBUFF,18
  else
    for p=0 to 4
      FBUFF(p)=0
    next
  endif
  return

REM Private method GPSTR
REM 1st param: JIS/EUC/UTF string
REM return: string with PCG set
LABEL GPSTR
  t$=""
  i=0
  if 1=MODE then
  	goto EUCSTR
  elseif 2=MODE then
  	goto UTFSTR
  else
  	goto EUCSTR
  endif

REM Private method EUCSTR
REM supports EUC-JP string
LABEL EUCSTR
  while i<len(args$(1))
    b=peek(args(1)+i)
    if 0xa0<b then
      REM Detect Kanji
      REM Get EUC code in var j
      j=b*256+peek(args(1)+i+1)
      i=i+2
      REM GPrint character
      gosub GPRTCH,j
    elseif 0x20<=b and b<0x80 then
      REM 7 bit character
      gosub GPRTCH,b
      i=i+1
    endif
  wend
  return

REM Private method UTFSTR
REM supports UTF-8 string
LABEL UTFSTR
  while i<len(args$(1))
    b=peek(args(1)+i)
    if 0xc0 = (0xe0 and b) then
      REM Get Unicode in j
      j=((b and 0x1f)<<6)+(peek(args(1)+i+1) and 0x3f)
      i=i+2
      REM GPrint character
      gosub GPRTCH,j
    elseif 0xe0 = (0xf0 and b) then
      REM Get Unicode in j
      j=((b and 0x0f)<<12)+((peek(args(1)+i+1) and 0x3f)<<6)+(peek(args(1)+i+2) and 0x3f)
      i=i+3
      REM GPrint character
      gosub GPRTCH,j
    elseif 0x20<=b and b<0x80 then
      REM 7 bit character
      gosub GPRTCH,b
      i=i+1
    endif
  wend
  return
