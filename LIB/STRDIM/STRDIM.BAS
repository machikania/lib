rem STRDIM class ver 0.3
rem Minimum version of KM-BASIC: KM-1501/KM-1303/KM-1208

useclass MA

field private strdat,nump

rem Constructor
method INIT
  var v
  v=system(2)
  v=val(v$(3))
  if 1200<=v AND v<1208 or 1300<=v AND v<1303 or 1500<=v AND v<1501 then
    print "Latest version of KM-BASIC is required"
    end
  endif
  nump=args(0)
  if 0=nump then
    print "Argument(s) required for cleating STRARRAY object"
    end
  elseif 1=nump then
    dim strdat(args(1))
  elseif 2=nump then
    dim strdat(args(1),args(2))
  elseif 3=nump then
    dim strdat(args(1),args(2),args(3))
  elseif 4=nump then
    dim strdat(args(1),args(2),args(3),args(4))
  elseif 5=nump then
    dim strdat(args(1),args(2),args(3),args(4),args(5))
  else
    print "Too many arguments"
    end
  endif
return

rem Get the string
method GETSTR
  var t
  if nump!=args(0) then
    goto e2
  elseif 1=nump then
    t=strdat(args(1))
  elseif 2=nump then
    t=strdat(args(1),args(2))
  elseif 3=nump then
    t=strdat(args(1),args(2),args(3))
  elseif 4=nump then
    t=strdat(args(1),args(2),args(3),args(4))
  else
    t=strdat(args(1),args(2),args(3),args(4),args(5))
  endif
  if t then return t
return ""

rem Set the string
method SETSTR
label SSTR
  var t,n,c
  if nump+1!=args(0) then
    goto e2
  endif
  rem Determine length
  t=args(1)
  n=0
  do while peek(t+n)
    n=n+1
  loop
  rem Create string object
  c=new(MA,n+1)
  t=c.memadr
  delete c
  rem Copy string
  n=0
  do
    c=peek(args(1)+n)
    poke t+n,c
    n=n+1
  loop while c
  rem Register string object to array
  if 1=nump then
    delete strdat(args(2))
    strdat(args(2))=t
  elseif 2=nump then
    delete strdat(args(2),args(3))
    strdat(args(2),args(3))=t
  elseif 3=nump then
    delete strdat(args(2),args(3),args(4))
    strdat(args(2),args(3),args(4))=t
  elseif 4=nump then
    delete strdat(args(2),args(3),args(4),args(5))
    strdat(args(2),args(3),args(4),args(5))=t
  else
    delete strdat(args(2),args(3),args(4),args(5),args(6))
    strdat(args(2),args(3),args(4),args(5),args(6))=t
  endif
return

rem Let string be
METHOD LETSTR
  if nump+1!=args(0) then
    goto e2
  elseif 1=nump then
    return gosub(SSTR,args(2),args(1))
  elseif 2=nump then
    return gosub(SSTR,args(3),args(1),args(2))
  elseif 3=nump then
    return gosub(SSTR,args(4),args(1),args(2),args(3))
  elseif 4=nump then
    return gosub(SSTR,args(5),args(1),args(2),args(3),args(4))
  else
    return gosub(SSTR,args(6),args(1),args(3),args(3),args(4),args(5))
  endif

rem Error handling
label e2
  print "Wrong argument number"
  end
