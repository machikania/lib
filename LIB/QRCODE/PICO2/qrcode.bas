REM ************************
REM * Class QRCODE ver 0.2 *
REM *  written by Katsumi  *
REM ************************

useclass CLDHEX
static private C_CODE
field public QSIZE
field private QRC

rem Constructor
rem 1st argument: string for the code
rem 2nd argument: Error correction level (0, 1, 2, or 3; default: 2) 

method INIT
  var t,b,e
  rem Initialize
  if not(C_CODE) then
    t$=getdir$()
    setdir "\\LIB\\QRCODE\\PICO2\\HEX"
    gosub INIT_C
    setdir t$
    delete t
  endif
  rem Check arguments
  if args(0)<1 then
    print "QRCODE: a string required for the object"
    end
  elseif args(0)<2 then
    e=2
  else
    e=args(2)
    if e<0 or 3<e then e=2
  endif
  rem Create QR code
  dim QRC(1023)
  dim b(1023)
  t=args(1)
  e=gosub(C_QRCODEGEN_ENCODETEXT_WRAPPED,t,b,QRC,e)
  delete b
  if 0=e then
    print "QRCODE: error occured when creating QR code"
  endif
  QSIZE=gosub(C_QRCODEGEN_GETSIZE,QRC)
return

rem DRAWQR method
rem 1st argument (var d): dot width          (default: 4)
rem 2nd argument (var b): border width       (default: 4)
rem 3rd argument (var c): color palette      (default: 0)
rem 4th argument (var p): background palette (default: 7)

method DRAWQR
  rem Parameters
  var d,b,c,p
  d=4:b=4:c=0:p=7
  if 0<args(0) then d=args(1)
  if 1<args(0) then b=args(2)
  if 2<args(0) then c=args(3)
  if 3<args(0) then p=args(4)
  b=b*d
  rem axes values
  var x,y,i,j
  x=system(28)+b
  y=system(29)+b
  rem draw border
  if b then boxfill x-b,y-b,x+QSIZE*d-1+b,y+QSIZE*d-1+b,p
  rem draw QR code
  for i=0 to QSIZE-1
    for j=0 to QSIZE-1
      if gosub(C_QRCODEGEN_GETMODULE,QRC,i,j) then boxfill x+i*d,y+j*d,x+(i+1)*d-1,y+(j+1)*d-1,c
    next
  next
return

method GETMODULE
  var x,y
  x=args(1)
  y=args(2)
return gosub(C_QRCODEGEN_GETMODULE,QRC,x,y)

label INIT_C_LDHEX
  var a
  a=gosub(INIT_C_LDHEX_SUB,"QRCODE02.HEX",$20002000,24576)
  if a then return a
  a=gosub(INIT_C_LDHEX_SUB,"QRCODE04.HEX",$20004000,24576)
  if a then return a
  a=gosub(INIT_C_LDHEX_SUB,"QRCODE08.HEX",$20008000,24576)
  if a then return a
  a=gosub(INIT_C_LDHEX_SUB,"QRCODE0c.HEX",$2000c000,24576)
  if a then return a
  a=gosub(INIT_C_LDHEX_SUB,"QRCODE10.HEX",$20010000,24576)
  if a then return a
  a=gosub(INIT_C_LDHEX_SUB,"QRCODE18.HEX",$20018000,24576)
  if a then return a
  a=gosub(INIT_C_LDHEX_SUB,"QRCODE20.HEX",$20020000,24576)
  if a then return a
  print "HEX file cannot be loaded!"
  end

label INIT_C_LDHEX_SUB
  var d
  dim d(0)
  if args(2)<d+8 then
    delete d
    return 0
  endif
  delete d
  C_CODE=new(CLDHEX,args(1),args(2),args(3))
  return args(2)

label INIT_C
  var A,V
  REM Load the main code
  A=gosub(INIT_C_LDHEX)
  REM data_cpy_table
  REM Link functions
  V=(A+5660-DATAADDRESS(C_MACHIKANIA_INIT)-12)>>1
  poke16 DATAADDRESS(C_MACHIKANIA_INIT)+8,$f000+(V>>11)
  poke16 DATAADDRESS(C_MACHIKANIA_INIT)+10,$f800+(V and $7ff)
  V=(A+844-DATAADDRESS(C_QRCODEGEN_ENCODETEXT_WRAPPED)-12)>>1
  poke16 DATAADDRESS(C_QRCODEGEN_ENCODETEXT_WRAPPED)+8,$f000+(V>>11)
  poke16 DATAADDRESS(C_QRCODEGEN_ENCODETEXT_WRAPPED)+10,$f800+(V and $7ff)
  V=(A+4944-DATAADDRESS(C_QRCODEGEN_GETSIZE)-12)>>1
  poke16 DATAADDRESS(C_QRCODEGEN_GETSIZE)+8,$f000+(V>>11)
  poke16 DATAADDRESS(C_QRCODEGEN_GETSIZE)+10,$f800+(V and $7ff)
  V=(A+4948-DATAADDRESS(C_QRCODEGEN_GETMODULE)-12)>>1
  poke16 DATAADDRESS(C_QRCODEGEN_GETMODULE)+8,$f000+(V>>11)
  poke16 DATAADDRESS(C_QRCODEGEN_GETMODULE)+10,$f800+(V and $7ff)
  REM Initialize C global variables
  gosub C_MACHIKANIA_INIT
return

label C_MACHIKANIA_INIT
  exec $68f0,$6931,$6972,$69b3,$f000,$f800,$bd00
label C_QRCODEGEN_ENCODETEXT_WRAPPED
  exec $68f0,$6931,$6972,$69b3,$f000,$f800,$bd00
label C_QRCODEGEN_GETSIZE
  exec $68f0,$6931,$6972,$69b3,$f000,$f800,$bd00
label C_QRCODEGEN_GETMODULE
  exec $68f0,$6931,$6972,$69b3,$f000,$f800,$bd00
