REM IR remote control transmitter class (NEC format)
REM IR_TX.BAS

REM Usage:
REM T=NEW(IR_TX,P)
REM  Initialize
REM  P:PWM Number (optional,default:1)

REM METHOD TX(C,D [,N])
REM  Transmit data
REM  C:customer code (16bit)
REM  D:data (8bit)
REM  N:number of repetition (optional)

REM METHOD TX2(D [,N])
REM  Transmit raw data
REM  D:raw data (32bit)
REM  N:number of repetition (optional)

REM METHOD REPEAT()
REM  Transfer last data again
REM  If it's within 108ms since the last transmission, wait and then transmit repeat code

REM Notice!
REM This class uses TIMER function


STATIC PRIVATE PWMNO,MODT,PRVDAT

METHOD INIT
 IF ARGS(0)=0 THEN PWMNO=1 ELSE PWMNO=ARGS(1)
 MODT=562
 PRVDAT=0
RETURN

METHOD TX
 VAR D
 D=(ARGS(1)<<16)+(ARGS(2)<<8)+(ARGS(2) XOR $FF)
 IF ARGS(0)<3 THEN
  GOSUB TXFER,D,0
 ELSE
  GOSUB TXFER,D,ARGS(3)-1
 ENDIF
RETURN

METHOD TX2
 IF ARGS(0)<2 THEN
  GOSUB TXFER,ARGS(1),0
 ELSE
  GOSUB TXFER,ARGS(1),ARGS(2)-1
 ENDIF
RETURN

METHOD REPEAT
 IF PRVDAT=0 THEN RETURN
 IF TIMER() THEN
  GOSUB TXFER,PRVDAT,0
 ELSE
  DO UNTIL TIMER():IDLE:LOOP
  TIMER 0
  PWM 333,38000,PWMNO:DELAYUS MODT*16
  PWM   0,38000,PWMNO:DELAYUS MODT*4
  PWM 333,38000,PWMNO:DELAYUS MODT
  PWM   0,38000,PWMNO
 ENDIF
RETURN

LABEL TXFER
 VAR D,I
 USETIMER 108000
 D=ARGS(1)
 PRVDAT=D
 PWM 333,38000,PWMNO:DELAYUS MODT*16
 PWM   0,38000,PWMNO:DELAYUS MODT*8

 FOR I=1 TO 32
  PWM 333,38000,PWMNO:DELAYUS MODT
  PWM   0,38000,PWMNO
  IF D AND $80000000 THEN
   DELAYUS MODT*3
  ELSE
   DELAYUS MODT
  ENDIF
  D=D<<1
 NEXT
 PWM 333,38000,PWMNO:DELAYUS MODT
 PWM   0,38000,PWMNO
 IF ARGS(2)=0 THEN RETURN

 FOR I=1 TO ARGS(2)
  DO UNTIL TIMER():IDLE:LOOP
  TIMER 0
  PWM 333,38000,PWMNO:DELAYUS MODT*16
  PWM   0,38000,PWMNO:DELAYUS MODT*4
  PWM 333,38000,PWMNO:DELAYUS MODT
  PWM   0,38000,PWMNO
 NEXT
RETURN
