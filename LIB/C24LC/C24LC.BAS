REM C24LC.BAS ver 0.11
REM Class C24LC for MachiKania Type M 
REM using I2C 8-pin EEPROM 24LC512
REM Multiple objects can be created
REM for multiple (up to 8) chips
REM Page size is 128 bytes

FIELD PUBLIC ADDR
FIELD PRIVATE ADDR7
USEVAR BUFF,NUM

REM Constructor needs slave address
REM from 0 to 7 (default 0)
REM Second argument is clock
REM (default 400)
METHOD INIT
  REM Resolve address
  if args(0)<1 then
    ADDR7=0x50
  elseif 0<=args(1) and args(1)<=7 then
    ADDR7=0x50+args(1)
  else
    print "Invalid 24LC512 address ";
    print args(1)
    end
  endif
  REM Initialize
  if args(0)<2 then
    I2C 400
  elseif 12<=args(2) and args(2)<=400 then
    I2C args(2)
  else
    print "Invalid I2C clock ";
    print args(2)
    end
  endif
  REM Check connection
  I2CWRITE ADDR7
  if I2CERROR() then
    print "24LC512 is not connected ";
    print "at address, ";args(1)
    end
  endif
  REM Initiate buffer
  if not(BUFF) then dim BUFF(1)
  REM All initiations done
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
  I2CWRITEDATA ADDR7,BUFF+2,NUM+2
  REM Increment address
  ADDR=(ADDR+NUM) and 0xffff
  REM Wait during writing process
  do
    I2CWRITE ADDR7
  loop while I2CERROR()
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
  I2CWRITEDATA ADDR7,args(1),args(2),ADDR>>8,ADDR
  ADDR=(ADDR+args(2)) and 0xffff
  do
    I2CWRITE ADDR7
  loop while I2CERROR()
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
  I2CREADDATA ADDR7,BUFF,NUM,ADDR>>8,ADDR
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
  I2CREADDATA ADDR7,args(1),args(2),ADDR>>8,ADDR
  ADDR=(ADDR+args(2)) and 0xffff
  return

REM RDSTR: Read string
METHOD RDSTR
  var T
  dim T(31)
  REM 1st parameter is address
  if 1<=args(0) then ADDR=args(1)
  I2CREADDATA ADDR7,T,128,ADDR>>8,ADDR
  for NUM=0 to 127
    if not(PEEK(T+NUM)) then break
  next
  NUM=NUM+1
  ADDR=(ADDR+NUM) and 0xffff
  return T$
