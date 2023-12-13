REM GEN3O.BAS ver 0.2.1
REM Class GEN3O for MachiKania type Z/M/P
REM using Saurce Han Sans Japanese font

useclass MA

REM General data used for all objects
static private FBUFF,FBSIZE

REM Object fields
field private ENCODE,FULLW,HALFW,HEIGHT,BOLD
field public DWIDTH

method INIT
  REM args(3): Bold or not
  if 2<args(0) then
    if args(3) and 1 then
      BOLD=1
    else
      BOLD=0
    endif
  else
    BOLD=1
  endif
  REM args(1): Font size
  if args(1)=58 then
    REM 48x58/32x58 font
    if FBSIZE<348 then
      dim FBUFF(86)
      FBSIZE=348
    endif
    FULLW=48
    HALFW=32
    HEIGHT=58
  elseif args(1)=44 then
    REM 36x44/24x44 font
    if FBSIZE<198 then
      dim FBUFF(49)
      FBSIZE=198
    endif
    FULLW=36
    HALFW=24
    HEIGHT=44
  elseif args(1)=29 then
    REM 24x29/16x29 font
    if FBSIZE<87 then
      dim FBUFF(21)
      FBSIZE=87
    endif
    FULLW=24
    HALFW=16
    HEIGHT=29
  else
    print "GEN3O: Illegal font size: ";args(1)
    print "Valid size: 29, 44 or 58"
    end
  endif
  REM args$(2): Encoding type
  if 1<args(0) then
    if 0=strncmp("EUC-JP",args$(2),7) then
      ENCODE=1
    elseif 0=strncmp("UTF-8",args$(2),6) then
      ENCODE=2
    else
      print "Illegal encoding:";args$(2)
      end
    endif
  else
    REM Default: EUC-JP
    ENCODE=1
  endif
return

label getwid
  var t
  t=args(1)
  DWIDTH=0
  while peek(t)
    if peek(t)<0x80 then
      DWIDTH=DWIDTH+HALFW
      t=t+1
      continue
    endif
    if 1=ENCODE then
      rem EUC-JP
      DWIDTH=DWIDTH+FULLW
      t=t+2
    elseif 2=ENCODE then
      rem UTF-8
      DWIDTH=DWIDTH+FULLW
      if 0xf0<=peek(t) then
        t=t+4
      elseif 0xe0<=peek(t) then
        t=t+3
      else
        t=t+2
      endif
    else
      rem SJIS (note that 0xA1-0xDF will be full width kana-moji
      DWIDTH=DWIDTH+FULLW
      t=t+2
    endif
  loop
return DWIDTH

rem GETBMP methid
rem args$(1): string
rem args(2):  color of character
rem args(3):  color of background

method GETBMP
  rem t: string
  rem m: memory address of object
  rem p: current position of memory to draw character
  rem c: color of character
  rem b: color of background
  rem j: JIS code
  rem d: current directory or temporary font data
  var t,m,p,c,b,j,d
  t=args(1)
  c=args(2)
  b=args(3)
  d$=getdir$()
  setdir "\\LIB\\GEN3O"
  gosub getwid,t
  m=new(MA,DWIDTH*HEIGHT)
  p=m.memadr
  delete m
  m=p
  while peek(t)
    if peek(t)<0x80 then
      rem half width character
      gosub DRAWH,p,peek(t),c,b
      t=t+1
      p=p+HALFW
    else
      rem full width character
      j=gosub(GETJIS,t)
      t=t+(j>>16)
      j=j and 0xffff
      gosub DRAWF,p,j,c,b
      p=p+FULLW
    endif
  loop
  setdir d$
return m

rem GPRT methid
rem args$(1): string
rem args(2):  color of character
rem args(3):  color of background

method GPRT
  var t,c,b,m
  t=args(1)
  c=args(2)
  b=args(3)
  m=gosub(GETBMP,t,c,b)
  putbmp ,DWIDTH,HEIGHT,m
  delete m
  point system(28)+DWIDTH,system(29)
return

rem DRAWH subroutine
rem args(1): pointer to draw a character
rem args(2): ascii code
rem args(3): color of character
rem args(4): color of background

label DRAWH
  rem c: character
  rem d: temporary font data
  rem x: x axis
  rem y: y axis
  var c,d,x,y
  rem Fetch ascii code
  c=args(2)
  if c<0x20 or 0x7e<c then c=0x3f
  rem Read from file
  if BOLD then
    fopen "half"+dec$(HEIGHT)+".bin","r"
  else
    fopen "half"+dec$(HEIGHT)+"p.bin","r"
  endif
  fseek ((HALFW+7)>>3)*HEIGHT*(c-0x20)
  fget FBUFF,((HALFW+7)>>3)*HEIGHT
  fclose
  rem copy data to canvas
  for y=0 to HEIGHT-1
    for x=0 to HALFW
      if 0=(x and 7) then
        d=peek(FBUFF+(x>>3)+((HALFW+7)>>3)*y)
      else
        d=d<<1
      endif
      if d and 0x80 then
        poke args(1)+x+DWIDTH*y,args(3)
      else
        poke args(1)+x+DWIDTH*y,args(4)
      endif
    next
  next
return

rem DRAWF subroutine
rem args(1): pointer to draw a character
rem args(2): JIS code
rem args(3): color of character
rem args(4): color of background

label DRAWF
  rem c: character
  rem d: temporary font data
  rem x: x axis
  rem y: y axis
  rem j: JIS code
  var c,d,x,y,j
  rem Fetch ascii code
  c=args(2)
  if c<0x20 or 0x7e<c then c=0x3f
  rem Read from file
  if BOLD then
    fopen "full"+dec$(HEIGHT)+".bin","r"
  else
    fopen "full"+dec$(HEIGHT)+"p.bin","r"
  endif
  j=args(2)
  if j<=0x287f then
    j=j-0x2120
    j=(j>>8)*0x60 + (j and 0xff)
  else
    j=j-0x3020
    j=(j>>8)*0x60 + (j and 0xff) + 0x300
  endif
  fseek ((FULLW+7)>>3)*HEIGHT*j
  fget FBUFF,((FULLW+7)>>3)*HEIGHT
  fclose
  rem copy data to canvas
  for y=0 to HEIGHT-1
    for x=0 to FULLW
      if 0=(x and 7) then
        d=peek(FBUFF+(x>>3)+((FULLW+7)>>3)*y)
      else
        d=d<<1
      endif
      if d and 0x80 then
        poke args(1)+x+DWIDTH*y,args(3)
      else
        poke args(1)+x+DWIDTH*y,args(4)
      endif
    next
  next
return

rem GETJIS subroutine
rem args$(1): string

label GETJIS
  var j
  if 2=ENCODE then
    rem UTF-8
    j=peek(args(1))
    if j<0xe0 then
      j=((j and 0x1f)<<6) or (peek(args(1)+1) and 0x3f)
      j=gosub(UNI2J,j)+0x20000
    elseif j<0xf0 then
      j=((j and 0x0f)<<12) or ((peek(args(1)+1) and 0x3f)<<6) or (peek(args(1)+2) and 0x3f)
      j=gosub(UNI2J,j)+0x30000
    else
      j=0x42129
    endif
  else
    rem EUC-JP
    j=peek(args(1))-0x80
    j=(j<<8) + peek(args(1)+1)-0x80
    j=j+0x20000: rem always 2 bytes
  endif
return j

rem UNI2J subroutine
rem args(1): Unicode

label UNI2J
  var j
  fopen "uni2jis.bin","r"
  fseek args(1)*2
  fget &j,2
  fclose
return j and 0xffff
