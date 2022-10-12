REM STRING.BAS ver 0.1
REM Class STRING for MachiKania Type Z/M/P
REM for handling string as a class object

REM There must be only one public field
FIELD PUBLIC STR$
STATIC PRIVATE RES$

REM constructor
METHOD INIT
  if args(0)=0 then
    STR$=""
  else
    STR$=""+args$(1)
  endif
  return

REM Public method CHARAT
METHOD CHARAT
  return peek(STR+args(1))

REM Public method EQUALS
METHOD EQUALS
  if len(STR$)!=len(args$(1)) then return 0
  return not(strncmp(STR$,args$(1),len(STR$)))

REM Public method INDEX
METHOD INDEX
  var p
  if 0<=args(1) and args(1)<=255 then
    REM args(1) is a character
    for p=0 to len(STR$)-1
      if peek(STR+p)=args(1) then return p
    next
    return -1
  endif
  REM args$(1) is string
  for p=0 to len(STR$)-len(args$(1))
    if peek(STR+p)!=peek(args(1)) then continue
    if 0=strncmp(STR$(p),args$(1),len(args$(1))) then return p
  next
  return -1

REM Public method LINDEX
METHOD LINDEX
  var p
  if 0<=args(1) and args(1)<=255 then
    REM args(1) is a character
    for p=len(STR$)-1 to 0 step -1
      if peek(STR+p)=args(1) then return p
    next
    return -1
  endif
  REM args$(1) is string
  for p=len(STR$)-len(args$(1)) to 0 step -1
    if peek(STR+p)!=peek(args(1)) then continue
    if 0=strncmp(STR$(p),args$(1),len(args$(1))) then return p
  next
  return -1

REM Public method LENGTH
METHOD LENGTH
  return len(STR$)

REM Public method REPLC
METHOD REPLC
  var p
  RES$=""
  for p=0 to len(STR$)-1
    if peek(STR+p)!=peek(args(1)) then
      REM First character doesn't match
      RES$=RES$+chr$(peek(STR+p))
      continue
    endif
    if strncmp(STR$(p),args$(1),len(args$(1))) then
      REM String doesn't match
      RES$=RES$+chr$(peek(STR+p))
      continue
    endif
    REM String matches. Let's replace
    RES$=RES$+args$(2)
    p=p+len(args$(1))-1
  next
  return RES$

REM Public method SUBSTR
METHOD SUBSTR
  if args(0)=1 then return STR$(args(1))
  if args(0)=2 then return STR$(args(1),args(2))
  return STR$

REM Public method LCASE
METHOD LCASE
  var p,b
  RES$=""+STR$
  for p=0 to len(RES$)-1
    b=peek(RES+p)
    if 0x41<=b and b<=0x5a then poke RES+p,b+0x20
  next
  return RES

REM Public method UCASE
METHOD UCASE
  var p,b
  RES$=""+STR$
  for p=0 to len(RES$)-1
    b=peek(RES+p)
    if 0x61<=b and b<=0x7a then poke RES+p,b-0x20
  next
  return RES

REM Public method TRIM
METHOD TRIM
  var p
  RES$=""+STR$
  if args(0)=1 then
    if args(1)=1 then
      REM L-trim
      for p=0 to len(RES$)-1
        if 0x20<peek(RES+p) then return RES+p
      next
      return ""
    elseif args(1)=2 then
      REM R-trim
      for p=len(RES$)-1 to 0 step -1
        if 0x20<peek(RES+p) then
          poke RES+p+1,0
          return RES
        endif
      next
      return ""
    endif
  endif
  REM R-trim
  for p=len(RES$)-1 to 0 step -1
    if 0x20<peek(RES+p) then
      poke RES+p+1,0
      break
    endif
  next
  REM L-trim
  for p=0 to len(RES$)-1
    if 0x20<peek(RES+p) then return RES+p
  next
  return ""
