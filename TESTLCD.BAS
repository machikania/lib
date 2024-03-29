REM QVGA LCD Library Sample Progarm 
REM  for MachiKania type M

USEVAR LCD

USECLASS IL9325
LCD=NEW(IL9325,1,8,9,10,11,12):REM Init LCD
REM LCD=NEW(IL9325,1,11,10,9,8,12):REM Init LCD

REM USECLASS IL9341
REM LCD=NEW(IL9341,1,8,9,10,11,12):REM Init LCD

CALL LCD.CLR()
CALL LCD.PRT(80, 90,$FFFFFF,-1,"MachiKania")
CALL LCD.PRT(80,100,$FFFF00,-1,"type M")
CALL LCD.PRT(80,110,$00FFFF,-1,"QVGA LCD")
CALL LCD.PRT(80,120,$00FF00,-1,"BASIC")
CALL LCD.PRT(80,130,$FF00FF,-1,"Library")

FOR I=0 TO 240 STEP 10
 CALL LCD.LIN(I,0,239,I,$00FF00)
 CALL LCD.LIN(239,I,239-I,239,$FF0000)
 CALL LCD.LIN(239-I,239,0,239-I,$0000FF)
 CALL LCD.LIN(0,239-I,I,0,$FFFFFF)
NEXT

CALL LCD.CLR():WAIT 60

FOR I=1 TO 50
 CALL LCD.LIN(RND()%240,RND()%320,RND()%240,RND()%320,GOSUB(RNDCOL))
NEXT

WAIT 60

FOR I=1 TO 50
 CALL LCD.CIR(RND()%240,RND()%320,RND()%150,GOSUB(RNDCOL))
NEXT

WAIT 60

FOR I=1 TO 20
 CALL LCD.BOXF(RND()%240,RND()%320,RND()%240,RND()%320,GOSUB(RNDCOL))
NEXT

WAIT 60

FOR I=1 TO 20
 CALL LCD.CIRF(RND()%240,RND()%320,RND()%100,GOSUB(RNDCOL))
NEXT

END

LABEL RNDCOL:REM Return 24bit Random Color
RETURN (RND()<<9)+(RND() AND $1FF)
