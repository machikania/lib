REM CKNJ8.BAS ver 0.5
REM Class CKNJ8 for MachiKania Type Z/M/P
REM using Misaki 8x8 font

USECLASS MA

REM General data used for gprint mode
STATIC PRIVATE CACHE,CNUM,MODE,FBUFF,FO

REM Data used for object for putbmp
STATIC PUBLIC DWIDTH

METHOD INIT
  REM File buffer size is 8 bytes
  dim FBUFF(1)
  REM use 158 PCG fonts
  dim CACHE(157)
  REM CNUM=0-127 correspond 0x80-0xFF, CNUM=128-136 do 0x01-0x09,
  REM and CNUM=137-157 do 0x0b-0x1f
  CNUM=0
  REM Use PCG
  usepcg
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

REM Public method, PRT and GPRT
REM 1st argument: string to print
METHOD PRT
  var t$,b,i,j
  fclose
  FO=0
  t$=gosub$(MKSTR,args$(1))
  print t$;
  fclose
  return

METHOD GPRT
  var t$,b,i,j
  fclose
  FO=0
  t$=gosub$(MKSTR,args$(1))
  j=len(t$)-1
  for i=0 to j
    b=peek(t+i)
    if 0x0d=b then
      REM Carriage Return
      point 0,system(29)+8
      continue
    elseif system(22)<system(28)+8 then
      REM Carriage Return
      point 0,system(29)+8
    endif
    gprint ,args(2),args(3),chr$(b)
  next
  fclose
  return

METHOD GETBMP
  var t$,b,i,j,x,y,r
  fclose
  FO=0
  t$=gosub$(MKSTR,args$(1))
  b=len(t$)
  DWIDTH=b*8
  REM Create new data object for putbmp as r
  i=NEW(MA,DWIDTH*8)
  r=i.memadr
  delete i
  for x=0 to b-1
    REM Get PCG data address in i
    i=system(104)+peek(t+x)*8
    for y=0 to 7
      REM Get PCG low in j
      j=peek(i+y)
      REM Create BMP data for PUTBMP
      if j and 0x80 then poke r+y*DWIDTH+x*8,args(2) else poke r+y*DWIDTH+x*8,args(3)
      if j and 0x40 then poke r+y*DWIDTH+x*8+1,args(2) else poke r+y*DWIDTH+x*8+1,args(3)
      if j and 0x20 then poke r+y*DWIDTH+x*8+2,args(2) else poke r+y*DWIDTH+x*8+2,args(3)
      if j and 0x10 then poke r+y*DWIDTH+x*8+3,args(2) else poke r+y*DWIDTH+x*8+3,args(3)
      if j and 0x08 then poke r+y*DWIDTH+x*8+4,args(2) else poke r+y*DWIDTH+x*8+4,args(3)
      if j and 0x04 then poke r+y*DWIDTH+x*8+5,args(2) else poke r+y*DWIDTH+x*8+5,args(3)
      if j and 0x02 then poke r+y*DWIDTH+x*8+6,args(2) else poke r+y*DWIDTH+x*8+6,args(3)
      if j and 0x01 then poke r+y*DWIDTH+x*8+7,args(2) else poke r+y*DWIDTH+x*8+7,args(3)
    next
  next
  return r

METHOD GETDW
  return DWIDTH

REM Private method GETPCG
REM 1st param: JIS code # starting from 0x2121
REM return: Byte as PCG character
LABEL GETPCG
  var i
  for i=0 to 157
    if CACHE(i)=args(1) then
      REM Found in CACHE
      if i<128 then return 0x80+i
      if i<137 then return 0x01+i-128
      return 0x0b + i-137
    endif
  next
  REM Not found in CACHE
  REM Open the file and find it.
  gosub FGETCH,args(1)
  i=CNUM
  CNUM=CNUM+1
  if 157<=CNUM then CNUM=0
  if i<128 then
    i=0x80+i
  elseif i<137 then
    i=0x01+i-128
  else
    i=i-137
  endif
  pcg i,gosub(LE2BE,FBUFF(0)),gosub(LE2BE,FBUFF(1))
  return i

REM Private method FOP
REM 1st param: file name
LABEL FOP
  var t
  REM Try current directory
  if fopen(args$(1),"r") then return
  REM Try library directory
  t$=getdir$()
  setdir "\\LIB\\CKNJ8"
  fopen args$(1),"r"
  setdir t$
  delete t
  return

REM Private medthod FGETCH
REM 1st param: JIS code # starting from 0x2121
LABEL FGETCH
  var p
  if 0=FO then
    REM File isn't yet open
    REM open it 
    FO=1
    if 2=MODE then
      gosub FOP,"MISAKI.UNI"
    else
      gosub FOP,"MISAKI.JIS"
    endif
  endif
  p=args(1)
  if 2=MODE then
    REM UTF-8
    if p<0x0500 then
      p=p-0x500
    elseif p<0x2000 then
      REM ERR
    elseif p<0x2700 then
      p=p-0x2000+0x0500
    elseif p<0x3000 then
      REM ERR
    elseif p<0x3100 then
      p=p-0x3000+0x0c00
    elseif p<0x4e00 then
      REM ERR
    elseif p<0xa000 then
      p=p-0x4e00+0x0d00
    elseif p<0xff00 then
      REM ERR
    else
      p=p-0xff00+0x5f00
    endif
  else
    REM EUC
    p=p-0xa1a1
  endif
  fseek p*8
  fget FBUFF,8
  return

REM Private method MKSTR
REM 1st param: JIS/EUC/UTF string
REM return: string with PCG set
LABEL MKSTR
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
      REM Get PCG character and add to t$
      j=gosub(GETPCG,j)
      t$=t$+chr$(j)
    else
      t$=t$+chr$(b)
      i=i+1
    endif
  wend
  return t$

REM Private method UTFSTR
REM supports UTF-8 string
LABEL UTFSTR
  while i<len(args$(1))
    b=peek(args(1)+i)
    if 0xc0 = (0xe0 and b) then
      REM Get Unicode in j
      j=((b and 0x1f)<<6)+(peek(args(1)+i+1) and 0x3f)
      i=i+2
      REM Get PCG character and add to t$
      j=gosub(GETPCG,j)
      t$=t$+chr$(j)
    elseif 0xe0 = (0xf0 and b) then
      REM Get Unicode in j
      j=((b and 0x0f)<<12)+((peek(args(1)+i+1) and 0x3f)<<6)+(peek(args(1)+i+2) and 0x3f)
      i=i+3
      REM Get PCG character and add to t$
      j=gosub(GETPCG,j)
      t$=t$+chr$(j)
    else
      t$=t$+chr$(b)
      i=i+1
    endif
  wend
  return t$

REM Private method LE2BE
REM Note that PCG statement is big endian
LABEL LE2BE
  var i
  i=args(1)<<24
  i=i or ((args(1) and 0xff00) <<8)
  i=i or ((args(1) and 0xff0000) >>8)
  i=i or (args(1)>>24)
  return i
