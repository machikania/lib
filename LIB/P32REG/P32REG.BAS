REM P32REG.BAS ver 0.3
REM Class P32REG for MachiKania Type Z/M 
REM Prepare P32MX.S file containing
REM registor address information

USEVAR FNAME
USEVAR LSTR,RNAME,RET
USEVAR FBUFF,FPO,FEND
USEVAR RNUM,RLIST,RADLST

METHOD INIT
  var i
  FNAME$="P32MX.S"
  REM Make registor list
  RNUM=args(0)
  dim RLIST(RNUM),RADLST(RNUM)
  for i=0 to RNUM-1
    RLIST(i)=args(i+1)
  next
  REM Open file
  gosub FO
  REM Asign address
  gosub RDFILE
  delete FBUFF
  return

METHOD REGADR
  var i,j,t
  RNAME=args(1)
  if 1<=RNAME and RNAME<=RNUM then
    return RADLST(RNAME-1)
  endif
  j=len(RNAME$)
  RET=0
  for i=0 to RNUM-1
    t=RLIST(i)
    if STRNCMP(t$,RNAME$,j+1) then continue
    RET=RADLST(i)
    break
  next
  if RET then return RET
  print "Not initialized for ";RNAME$
  end

METHOD RDREG
  RET=gosub(REGADR,args(1))
  return RET(0)

METHOD WRREG
  RET=gosub(REGADR,args(1))
  RET(0)=args(2)
  return

REM Private method FOP
REM 1st param: file name
LABEL FOP
  var t
  REM Try current directory
  if fopen(args$(1),"r") then return
  REM Try library directory
  t$=getdir$()
  setdir "\\LIB\\P32REG"
  fopen args$(1),"r"
  setdir t$
  delete t
  return

LABEL FO
  REM Buffer contains 128 + 512 bytes
  dim FBUFF(159)
  gosub FOP,FNAME$
  FPO=128
  FEND=FPO+FGET(FBUFF,512)
  poke FBUFF+FPO-1,0x0A
  return

LABEL LINEIN
  REM Seek next return code (LF: 0x0A)
  do
    FPO=FPO+1
    if FEND<=FPO then break
  loop until 0x0A=peek(FBUFF+FPO-1)
  REM if less than 128 remaining,
  REM move the remaining string to 
  REM upper area and load another
  REM 512 byte block
  if 512<FPO and not(FEOF()) then
    for i=0 to 31
      FBUFF(i)=FBUFF(128+i)
    next
    FPO=FPO-512
    FEND=FEND-512+FGET(FBUFF+128,512)
  endif
  return FBUFF+FPO

LABEL RDFILE
  var j
  WHILE FPO<FEND
    LSTR=gosub(LINEIN)
    for j=0 to RNUM-1
      if (RADLST(j)) then continue
      RNAME=RLIST(j)
      REM Check if same name
      i=LEN(RNAME$)
      IF STRNCMP(RNAME$,LSTR$,i) THEN CONTINUE
      REM Check " = 0x"
      IF STRNCMP(LSTR$(i)," = 0x",5) THEN CONTINUE
      LSTR=LSTR+i+5
      REM Deternibe 32 bit value
      RET=0
      FOR i=0 TO 7
        RET=RET<<4
        IF PEEK(LSTR+i)<0x3A THEN
          RET=RET+PEEK(LSTR+i)-0x30
        ELSE
          RET=RET+PEEK(LSTR+i)-0x41+0x0A
        ENDIF
      NEXT
      RADLST(j)=RET
      REM Check if all done
      for i=0 to RNUM-1
        if not(RADLST(i)) then break
        if RNUM-1=i then FEND=FPO
      next
      if FEND<=FPO then BREAK
    next
  WEND
  FCLOSE
  return
