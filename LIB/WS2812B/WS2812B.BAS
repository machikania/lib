REM WS2812B Serial LED Control Class for MachiKania type P
REM WS2812B.BAS

REM Connection:
REM DIN -- IO bit x
REM VDD -- +5V
REM GND -- GND

REM Usage:
REM A=NEW(WS2812B,N,P)
REM  Init Buffer
REM  N:Number of LED
REM  P:IO bit number(0-7)

REM METHOD SETLED(Position,R,G,B)
REM  Set Serial LED Color
REM  Position:LED Number from the front
REM  R,G,B:Color (0-255)

REM METHOD CPYLED(Position1,Position2)
REM  Copy LED Color from Position1 to Postion2

REM METHOD PUTLED
REM  Output LEDBUF data to WS2812Bs


FIELD PRIVATE NUMLED,BUFLED,LEDBIT

METHOD INIT
 VAR I
 NUMLED=ARGS(1)
 LEDBIT=ARGS(2)
 IF LEDBIT>=8 OR LEDBIT<0 THEN
  PRINT "IO bit number must be 0-7"
  END
 ENDIF
 DIM BUFLED(NUMLED*3/4):REM LEDs buffer
 FOR I=0 TO NUMLED*3/4:BUFLED(I)=0:NEXT
 OUT LEDBIT,0
 LEDBIT=1<<LEDBIT
 DELAYUS 280
 GOSUB PUTLED
RETURN

METHOD SETLED
 REM SETLED(Position,R,G,B)
 VAR P
 IF ARGS(1)>=NUMLED THEN RETURN
 P=BUFLED+ARGS(1)*3
 POKE P  ,ARGS(3)
 POKE P+1,ARGS(2)
 POKE P+2,ARGS(4)
RETURN

METHOD CPYLED
 REM CPYLED(Position1,Position2)
 VAR P,Q
 IF ARGS(1)>=NUMLED THEN RETURN
 IF ARGS(2)>=NUMLED THEN RETURN
 P=BUFLED+ARGS(1)*3
 Q=BUFLED+ARGS(2)*3
 POKE Q  ,PEEK(P)
 POKE Q+1,PEEK(P+1)
 POKE Q+2,PEEK(P+2)
RETURN

METHOD PUTLED
 REM Output LEDBUF data to WS2812Bs
 VAR I,J,D,P
 P=BUFLED
 I=0:J=NUMLED*3*8
 WHILE I<J
  D=PEEK(P)<<(I AND 7)
  IF D AND $80 THEN
   EXEC $B672 :REM cpsid i(disable interrupt)
   POKE32 $D0000014,LEDBIT:REM OUT x,1
   I=I+0:REM dummy code
   I=I+1
   P=P+((I AND 7)=0)
   POKE32 $D0000018,LEDBIT:REM OUT x,0
   EXEC $B662 :REM cpsie i(enable interrupt)
  ELSE
   EXEC $B672 :REM cpsid i(disable interrupt)
   POKE32 $D0000014,LEDBIT:REM OUT x,1
   I=I+0:REM dummy code
   I=I+1
   POKE32 $D0000018,LEDBIT:REM OUT x,0
   EXEC $B662 :REM cpsie i(enable interrupt)
   P=P+((I AND 7)=0)
  ENDIF
 WEND
 DELAYUS 280
RETURN
