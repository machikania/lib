rem STRD2 class ver 0.1

field private strdat,nump
static private d1,d2,d3,d4,d5

rem The "numd" is required word (32 bit) number minus 4
static private numd

rem Set maximum length
method MAXLEN
  if 0=args(0) OR args(1)<0 OR 65535<args(1) then
    print "Incorrect length of string"
    end
  endif
  numd=(args(1)+1)/4-4
return

rem Constructor
method INIT
  nump=args(0)
  if 0=nump then
    print "Argument(s) required for cleating STRD2 object"
    end
  elseif 1=nump then
    if 0=d1 then
	    dim d1(args(1),numd+3)
	    strdat=d1
	elseif 0=d2 then
	    dim d2(args(1),numd+3)
	    strdat=d2
	elseif 0=d3 then
	    dim d3(args(1),numd+3)
	    strdat=d3
	elseif 0=d4 then
	    dim d4(args(1),numd+3)
	    strdat=d4
	elseif 0=d5 then
	    dim d5(args(1),numd+3)
	    strdat=d5
	else
	  goto e1
	endif
  elseif 2=nump then
    if 0=d1 then
      dim d1(args(1),args(2),numd+3)
      strdat=d1
	elseif 0=d2 then
      dim d2(args(1),args(2),numd+3)
      strdat=d2
	elseif 0=d3 then
      dim d3(args(1),args(2),numd+3)
      strdat=d3
	elseif 0=d4 then
      dim d4(args(1),args(2),numd+3)
      strdat=d4
	elseif 0=d5 then
      dim d5(args(1),args(2),numd+3)
      strdat=d5
	else
	  goto e1
	endif
  elseif 3=nump then
    if 0=d1 then
      dim d1(args(1),args(2),args(3),numd+3)
      strdat=d1
	elseif 0=d2 then
      dim d2(args(1),args(2),args(3),numd+3)
      strdat=d2
	elseif 0=d3 then
      dim d3(args(1),args(2),args(3),numd+3)
      strdat=d3
	elseif 0=d4 then
      dim d4(args(1),args(2),args(3),numd+3)
      strdat=d4
	elseif 0=d5 then
      dim d5(args(1),args(2),args(3),numd+3)
      strdat=d5
	else
	  goto e1
	endif
  elseif 4=nump then
    if 0=d1 then
      dim d1(args(1),args(2),args(3),args(4),numd+3)
      strdat=d1
	elseif 0=d2 then
      dim d2(args(1),args(2),args(3),args(4),numd+3)
      strdat=d2
	elseif 0=d3 then
      dim d3(args(1),args(2),args(3),args(4),numd+3)
      strdat=d3
	elseif 0=d4 then
      dim d4(args(1),args(2),args(3),args(4),numd+3)
      strdat=d4
	elseif 0=d5 then
      dim d5(args(1),args(2),args(3),args(4),numd+3)
      strdat=d5
	else
	  goto e1
	endif
  elseif 5=nump then
    if 0=d1 then
      dim d1(args(1),args(2),args(3),args(4),args(5),numd+3)
      strdat=d1
	elseif 0=d2 then
      dim d2(args(1),args(2),args(3),args(4),args(5),numd+3)
      strdat=d2
	elseif 0=d3 then
      dim d3(args(1),args(2),args(3),args(4),args(5),numd+3)
      strdat=d3
	elseif 0=d4 then
      dim d4(args(1),args(2),args(3),args(4),args(5),numd+3)
      strdat=d4
	elseif 0=d5 then
      dim d5(args(1),args(2),args(3),args(4),args(5),numd+3)
      strdat=d5
	else
	  goto e1
	endif
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
  for n=0 to 65535
    if 0=peek(t+n) then break
  next
  if numd*4+16<=n then
    print "String too long"
    end
  endif
  rem Get pointer to store string
  if 1=nump then
    t=strdat(args(2))
  elseif 2=nump then
    t=strdat(args(2),args(3))
  elseif 3=nump then
    t=strdat(args(2),args(3),args(4))
  elseif 4=nump then
    t=strdat(args(2),args(3),args(4),args(5))
  else
    t=strdat(args(2),args(3),args(4),args(5),args(6))
  endif
  rem Copy string
  n=0
  do
    c=peek(args(1)+n)
    poke t+n,c
    n=n+1
  loop while c
return

rem Let string be
METHOD LETSTR
  if nump+1!=args(0) then
    goto e2
  endif
  if 1=nump then
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
label e1
  print "Too many arrays"
  end
label e2
  print "Wrong argument number"
  end
