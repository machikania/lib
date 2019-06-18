REM C23LC.BAS ver 0.1
REM Class C23LC for MachiKania Type M 
REM using SPI 8-pin SRAM 23LC512

FIELD PUBLIC ADDR
USEVAR BUFF,NUM

REM Constructor. Parameters are: 
REM 1st: Clock. Default 20000
REM 2nd: CS port. Default 0x39

METHOD INIT
  var i
  dim BUFF(1)
  REM Initialize SPI module.
  if args(0)<1 then
    SPI 20000
  elseif args(0)<2 then
    SPI args(1)
  else
    SPI args(1),0,8,args(2)
  endif
  REM Check connection
  i=gosub(RD8,0) XOR 0xFF
  gosub WR8,i,0
  if gosub(RD8,0)!=i then
    print "SRAM 23LC512 not connected"
    end
  endif
  gosub WR8,i XOR 0xFF,0
  ADDR=0
  return

REM WR8: Write byte (8 bits)
METHOD WR8
  NUM=1
LABEL WRMAIN
  REM Second parameter is address
  if 2<=args(0) then ADDR=args(2)
  POKE BUFF+2,ADDR>>8
  POKE BUFF+3,ADDR
  REM First parameter is word to write
  BUFF(1)=args(1)
  SPIWRITEDATA BUFF+2,NUM+2,0x02
  REM Increment address
  ADDR=(ADDR+NUM) and 0xffff
  REM All done
  return

REM WR16: Write 16 bit word
METHOD WR16
  NUM=2
  goto WRMAIN

REM WR32: Write 32 bit word
METHOD WR32
  NUM=4
  goto WRMAIN

REM WRDATA: Write data
METHOD WRDATA
  REM 1st parameter is buffer
  REM 2nd parameter is # of write
  REM 3rd parameter is address
  if 3<=args(0) then ADDR=args(3)
  SPIWRITEDATA args(1),args(2),0x02,ADDR>>8,ADDR
  ADDR=(ADDR+args(2)) and 0xffff
  return

REM WRSTR: Write string
METHOD WRSTR
  REM 1st parameter is string
  REM 2nd parameter is address
  if 2<=args(0) then ADDR=args(2)
  gosub WRDATA,args(1),len(args$(1))+1
  return

REM RD8: Read byte (8 bits)
METHOD RD8
  NUM=1
LABEL RDMAIN
  REM First parameter is address
  if 1<=args(0) then ADDR=args(1)
  BUFF(0)=0
  SPIREADDATA BUFF,NUM,0x03,ADDR>>8,ADDR
  REM Increment address
  ADDR=(ADDR+NUM) and 0xffff
  REM All done
  return BUFF(0)

REM RD16: Read 16 bit word
METHOD RD16
  NUM=2
  goto RDMAIN

REM RD32: Read 32 bit word
METHOD RD32
  NUM=4
  goto RDMAIN

REM RDDATA: Read page
METHOD RDDATA
  REM 1st parameter is buffer
  REM 2nd parameter is # of write
  REM 3rd parameter is address
  if 3<=args(0) then ADDR=args(3)
  SPIREADDATA args(1),args(2),0x03,ADDR>>8,ADDR
  ADDR=(ADDR+args(2)) and 0xffff
  return

REM RDSTR: Read string
METHOD RDSTR
  var i,T
  REM 1st parameter is address
  if 1<=args(0) then ADDR=args(1)
  REM 2nd parameter is buffer size
  REM Default 128 bytes.
  if 2<=args(0) then NUM=args(2) else NUM=128
  dim T((NUM-1)/4)
  SPIREADDATA T,NUM,0x03,ADDR>>8,ADDR
  for i=0 to NUM-1
    if not(PEEK(T+i)) then break
  next
  NUM=i+1
  ADDR=(ADDR+NUM+1) and 0xffff
  return T$
