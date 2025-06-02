REM CLASS TSC2046
REM Ver 0.2.1
REM Connect T_IRQ to GP0 (pin #1), or to the port set in constructor argument #2
REM Connect T_CS to GP3 (pin #5), or to the port set in constructor argument #1
REM Connect T_OUT to GP16 (SPI MISO, pin #21)
REM Connect T_DIN to GP19 (SPI MOSI, pin #25)
REM Connect T_CLK to GP18 (SPI CLK, pin #24)
REM
REM For Waveshare ResTouch, call TSC2046::INIT(9,10)

useclass CRDINI

static private lcdturn,tirq,xmin,xmax,ymin,ymax,xflip,yflip
static public lastx,lasty

METHOD INIT
  REM Determine LCD direction
  crdini::init()
  if crdini::isset("HORIZONTAL") then
    lcdturn=0
  elseif crdini::isset("VERTICAL") then
    lcdturn=270
  elseif crdini::isset("LCD0TURN") then
    lcdturn=0
  elseif crdini::isset("LCD90TURN") then
    lcdturn=90
  elseif crdini::isset("LCD180TURN") then
    lcdturn=180
  elseif crdini::isset("LCD270TURN") then
    lcdturn=270
  else
    lcdturn=0
  endif
  REM Set SPI
  REM args(1): port number for T_CS (default: 3)
  if args(0)<1 then
    spi 2500,8,0,3
  else
    spi 2500,8,0,args(1)
  endif
  REM Set IRQ port number (default: 0)
  if args(0)<2 then
    tirq=0
  else
    tirq=args(2)
  endif
  REM Initialize x and y values
  lastx=-1
  lasty=-1
  REM Get minimum and maximum values
  gosub load4var
return

METHOD TOUCH
  if in(tirq) then return 0 else return 1

METHOD PORTRAIT
  var a
  if 0=lcdturn then
    lcdturn=270
  elseif 180=lcdturn then
    lcdturn=90
  else
    return
  endif
  a=lastx
  lastx=lasty
  lasty=a
return

METHOD LANDSCAPE
  var a
  if 270=lcdturn then
    lcdturn=0
  elseif 90=lcdturn then
    lcdturn=180
  else
    return
  endif
  a=lastx
  lastx=lasty
  lasty=a
return

METHOD POLLING
  var a,b,x,y,w,h
  if in(tirq) then return 0
  if 90=lcdturn or 270=lcdturn then
    w=system(23)-1
    h=system(22)-1
  else
    w=system(22)-1
    h=system(23)-1
  endif
  x=gosub(tscread,0x94)
  y=gosub(tscread,0xd4)
  a=gosub(tscread,0x94)
  b=gosub(tscread,0xd4)
  if in(tirq) then return 0
  if abs(x-a)>2 then return 0
  if abs(y-b)>2 then return 0
  x=(x+a)>>1
  y=(y+b)>>1
  x=w*(x-xmin)/(xmax-xmin)
  y=h*(y-ymin)/(ymax-ymin)
  if xflip then
    x=w-x
  elseif yflip then
    y=h-y
  endif
  if 0=lcdturn then
    lastx=w-x
    lasty=h-y
  elseif 90=lcdturn then
    lastx=h-y
    lasty=x
  elseif 180=lcdturn then
    lastx=x
    lasty=y
  else
    lastx=y
    lasty=w-x
  endif
return 1

label tscread
  REM i:counter, d: data, r: result, n:minimum, x:maximum
  var i,d,r,n,x
  r=0
  n=0xffff
  x=0
  for i=1 to 10
    d=args(1)
    spiswapdata &d,3
    d=((d and 0x7f00)>>3) or ((d and 0xf80000)>>19)
    r=r+d
    if d<n then n=d
    if x<d then x=d
  next
return (r-n-x)>>3

METHOD MINMAX
  var a,b,x,y,w,h
  w=system(22)
  h=system(23)
  cls
  if lcdturn=0 or lcdturn=180 then
    line 0,0,30,30:line 0,0,10,0:line 0,0,0,10
    line w-31,h-31,w-1,h-1:line w-11,h-1,w-1,h-1:line w-1,h-11,w-1,h-1
    cursor 0,15
    print "Draw lines on the allows several times."
    print "Then, press FIRE button."
  else
    line w-1,0,w-31,30:line w-1,0,w-11,0:line w-1,0,w-1,10
    line 0,h-1,30,h-31:line 0,h-1,10,h-1:line 0,h-1,0,h-11
    cursor 0,15
    print "Draw lines on the allows "
    print "several times."
    print "Then, press FIRE button."
  endif
  xmin=0xffff:xmax=0:ymin=0xffff:ymax=0:xflip=0:yflip=0
  do
    if keys(32) then break
    if in(tirq) then continue
    x=gosub(tscread,0x94)
    y=gosub(tscread,0xd4)
    a=gosub(tscread,0x94)
    b=gosub(tscread,0xd4)
    if in(tirq) then continue
    if abs(x-a)>2 then continue
    if abs(y-b)>2 then continue
    x=(x+a)>>1
    y=(y+b)>>1
    if x<xmin then xmin=x
    if xmax<x then xmax=x
    if y<ymin then ymin=y
    if ymax<y then ymax=y
    if x=xmin and y=ymin or x=xmax and y=ymax then
      xflip=0:yflip=0
    elseif x=xmin and y=ymax or x=xmax and y=ymin then
      yflip=1:xflip=0
    elseif x=xmax and y=ymin or x=xmin and y=ymax then
      xflip=1:yflip=0
    endif
    cursor 5,5:print hex$(xmin),hex$(xmax),
    cursor 5,6:print hex$(ymin),hex$(ymax),
  loop
  cls
  gosub save2file
return

label save2file
  var c
  c$=getdir$()
  setdir "/LIB/TSC2046"
  fopen "TSC2046.INI","w"
  fprint "XMIN=";xmin
  fprint "XMAX=";xmax
  fprint "YMIN=";ymin
  fprint "YMAX=";ymax
  fprint "XFLIP=";xflip
  fprint "YFLIP=";yflip
  fclose
  setdir c$
return

label load4var
  var c,t
  c$=getdir$()
  setdir "/LIB/TSC2046"
  if 0=fopen("TSC2046.INI","r") then
    REM Determine minimum and miximum values and save them to file
    gosub minmax
    fopen("TSC2046.INI","r")
  endif
  do until feof()
    t$=finput$()
    if 0=strncmp(t$,"XMIN=",5) then
      xmin=val(t$(5))
    elseif 0=strncmp(t$,"XMAX=",5) then
      xmax=val(t$(5))
    elseif 0=strncmp(t$,"YMIN=",5) then
      ymin=val(t$(5))
    elseif 0=strncmp(t$,"YMAX=",5) then
      ymax=val(t$(5))
    elseif 0=strncmp(t$,"XFLIP=",6) then
      xflip=val(t$(6))
    elseif 0=strncmp(t$,"YFLIP=",6) then
      yflip=val(t$(6))
    endif
  loop
  fclose
  endif
  setdir c$
return
