REM CRDINI.BAS ver 0.1
REM Class CRDINI for MachiKania Type Z/M/P

static private inifil

METHOD INIT
  var d,f
  d$=getdir$()
  setdir "\\"
  f$=system$(0)
  f$="MACHIKA"+f$(0,1)+".INI"
  inifil$=""
  if fopen(f$,"r") then
    do until feof()
      f$=finput$()
      if peek(f)<0x30 then continue
      inifil$=inifil$+f$
    loop
    fclose
  endif
  setdir d$
return

METHOD ISSET
  var i,l
  l=len(args$(1))
  i=0
  do while peek(inifil+i)
    if 0=strncmp(inifil$(i),args$(1),l) then return 1
    do while 0x20<=peek(inifil+i) or 0x09=peek(inifil+i)
      i=i+1
    loop
    do while 0x0d=peek(inifil+i) or 0x0a=peek(inifil+i)
      i=i+1
    loop
  loop
return 0

METHOD GETVAL
  var i,l,t
  t$=args$(1)+"="
  l=len(t$)
  i=0
  do while peek(inifil+i)
    if 0=strncmp(inifil$(i),t$,l) then
      i=i+l
      l=0
      do while 0x20<=peek(inifil+i+l)
        l=l+1
      loop
      return inifil$(i,l)
    endif
    do while 0x20<=peek(inifil+i) or 0x09=peek(inifil+i)
      i=i+1
    loop
    do while 0x0d=peek(inifil+i) or 0x0a=peek(inifil+i)
      i=i+1
    loop
  loop
return ""
