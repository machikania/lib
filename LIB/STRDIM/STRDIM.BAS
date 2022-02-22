rem STRDIM class ver 0.1

useclass ma16, ma64, ma256
field private strdat,nump
static private d1,d2,d3,d4,d5

rem Constructor
method INIT
  nump=args(0)
  if 0=nump then
    print "Argument(s) required for cleating STRARRAY object"
    end
  elseif 1=nump then
    if 0=d1 then
	    dim d1(args(1))
	    strdat=d1
	elseif 0=d2 then
	    dim d2(args(1))
	    strdat=d2
	elseif 0=d3 then
	    dim d3(args(1))
	    strdat=d3
	elseif 0=d4 then
	    dim d4(args(1))
	    strdat=d4
	elseif 0=d5 then
	    dim d5(args(1))
	    strdat=d5
	else
	  goto e1
	endif
  elseif 2=nump then
    if 0=d1 then
      dim d1(args(1),args(2))
      strdat=d1
	elseif 0=d2 then
      dim d2(args(1),args(2))
      strdat=d2
	elseif 0=d3 then
      dim d3(args(1),args(2))
      strdat=d3
	elseif 0=d4 then
      dim d4(args(1),args(2))
      strdat=d4
	elseif 0=d5 then
      dim d5(args(1),args(2))
      strdat=d5
	else
	  goto e1
	endif
  elseif 3=nump then
    if 0=d1 then
      dim d1(args(1),args(2),args(3))
      strdat=d1
	elseif 0=d2 then
      dim d2(args(1),args(2),args(3))
      strdat=d2
	elseif 0=d3 then
      dim d3(args(1),args(2),args(3))
      strdat=d3
	elseif 0=d4 then
      dim d4(args(1),args(2),args(3))
      strdat=d4
	elseif 0=d5 then
      dim d5(args(1),args(2),args(3))
      strdat=d5
	else
	  goto e1
	endif
  elseif 4=nump then
    if 0=d1 then
      dim d1(args(1),args(2),args(3),args(4))
      strdat=d1
	elseif 0=d2 then
      dim d2(args(1),args(2),args(3),args(4))
      strdat=d2
	elseif 0=d3 then
      dim d3(args(1),args(2),args(3),args(4))
      strdat=d3
	elseif 0=d4 then
      dim d4(args(1),args(2),args(3),args(4))
      strdat=d4
	elseif 0=d5 then
      dim d5(args(1),args(2),args(3),args(4))
      strdat=d5
	else
	  goto e1
	endif
  elseif 5=nump then
    if 0=d1 then
      dim d1(args(1),args(2),args(3),args(4),args(5))
      strdat=d1
	elseif 0=d2 then
      dim d2(args(1),args(2),args(3),args(4),args(5))
      strdat=d2
	elseif 0=d3 then
      dim d3(args(1),args(2),args(3),args(4),args(5))
      strdat=d3
	elseif 0=d4 then
      dim d4(args(1),args(2),args(3),args(4),args(5))
      strdat=d4
	elseif 0=d5 then
      dim d5(args(1),args(2),args(3),args(4),args(5))
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
  for n=0 to 256
    if 0=peek(t+n) then break
  next
  rem Create string object
  if n<16 then
    t=new(ma16)
  elseif n<64 then
    t=new(ma64)
  elseif n<256 then
    t=new(ma256)
  else
    print "String too long"
    end
  endif
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
