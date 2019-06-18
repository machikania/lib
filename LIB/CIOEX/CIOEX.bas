REM CIOEX.BAS ver 0.12
REM Class CIOEX for MachiKania Type M 
REM using I/O expander MCP23017

FIELD PRIVATE RET,ADDR7
FIELD PRIVATE TRISAV,TRISBV,LATAV,LATBV,CNPUAV,CNPUBV

REM Constructor
REM 1st argument is 3 bit address
REM  (default 0)
REM 2nd argument is clock frequency in kHz
REM   (default 400)
METHOD INIT
  REM Address setting
  if 1<=args(0) then ADDR7=args(1) else ADDR7=0
  ADDR7=0x20 OR (ADDR7 and 0x07)
  REM Initialize I2C
  if 2<=args(0) then I2C args(2) else I2C 400
  REM Initialize MCP23017
  REM Note that IOCON address is either
  REM 0x05 (BANK=1) or 0x0A (BANK=0)
  I2CWRITE ADDR7,0x05,0x00
  I2CWRITE ADDR7,0x0A,0x00
  if I2CERROR() then
    print "MCP23017 is not connected at ";ADDR7
    end
  endif
  REM Default values
  gosub TRISA,0xFF
  gosub TRISB,0xFF
  gosub CNPUA,0x00
  gosub CNPUB,0x00
  gosub LATA,0x00
  gosub LATB,0x00
  REM All intializations done
  return

REM TRISA():   Read current value
REM TRISA x:   Set byte value
REM TRISA x,y: Set bit value
METHOD TRISA
  if args(0)=0 then return TRISAV
  if args(0)=1 then
    gosub SET8,&TRISAV,0x00,args(1)
  else
    gosub SETBIT,&TRISAV,0x00,args(1),args(2)
  endif
  return

REM TRISB():   Read current value
REM TRISB x:   Set byte value
REM TRISB x,y: Set bit value
METHOD TRISB
  if args(0)=0 then return TRISBV
  if args(0)=1 then
    gosub SET8,&TRISBV,0x01,args(1)
  else
    gosub SETBIT,&TRISBV,0x01,args(1),args(2)
  endif
  return

REM LATA():   Read current value
REM LATA x:   Set byte value
REM LATA x,y: Set bit value
METHOD LATA
  if args(0)=0 then return LATAV
  if args(0)=1 then
    gosub SET8,&LATAV,0x14,args(1)
  else
    gosub SETBIT,&LATAV,0x14,args(1),args(2)
  endif
  return

REM LATB():   Read current value
REM LATB x:   Set byte value
REM LATB x,y: Set bit value
METHOD LATB
  if args(0)=0 then return LATBV
  if args(0)=1 then
    gosub SET8,&LATBV,0x15,args(1)
  else
    gosub SETBIT,&LATBV,0x15,args(1),args(2)
  endif
  return

REM CNPUA():   Read current value
REM CNPUA x:   Set byte value
REM CNPUA x,y: Set bit value
METHOD CNPUA
  if args(0)=0 then return CNPUAV
  if args(0)=1 then
    gosub SET8,&CNPUAV,0x0C,args(1)
  else
    gosub SETBIT,&CNPUAV,0x0C,args(1),args(2)
  endif
  return

REM CNPUB():   Read current value
REM CNPUB x:   Set byte value
REM CNPUB x,y: Set bit value
METHOD CNPUB
  if args(0)=0 then return CNPUBV
  if args(0)=1 then
    gosub SET8,&CNPUBV,0x0D,args(1)
  else
    gosub SETBIT,&CNPUBV,0x0D,args(1),args(2)
  endif
  return

REM PORTA():  Read current input byte value
REM PORTA(x): Read current x-th input bit value
METHOD PORTA
  RET=I2CREAD(ADDR7,0x12)
  if args(0)<1 then
    return RET
  elseif RET and (1<<args(1)) then
    return 0
  else
    return 1
  endif

REM PORTB():  Read current input byte value
REM PORTB(x): Read current x-th input bit value
METHOD PORTB
  RET=I2CREAD(ADDR7,0x13)
  if args(0)<1 then
    return RET
  elseif RET and (1<<args(1)) then
    return 0
  else
    return 1
  endif

REM SET8:         Set specific setting
REM 1st argument: pointer to val of private field
REM 2nd argument: address in MCP23017
REM 3rd argument: setting value in byte
LABEL SET8
  poke args(1), args(3) and 0xff
  I2CWRITE ADDR7,args(2),args(3)
  return

REM SETBIT:       Set specific bit
REM 1st argument: pointer to val of private field
REM 2nd argument: address in MCP23017
REM 3rd argument: setting bit position
REM 4th argument: setting value (1 or 0)
LABEL SETBIT
  var i
  i=1<<(args(3) and 0x07)
  if args(4) then
    i=peek(args(1)) or i
  else
    i=peek(args(1)) and (i xor 0xff)
  endif
  poke args(1),i
  I2CWRITE ADDR7,args(2),i
  return

