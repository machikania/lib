REM WGET.BAS ver 0.2
REM MachiKania class WGET for type P

static private pdata,header,ucheader

method FORSTRING
  var t,s,i
  if 1<args(0) then pdata$=args$(2)
  if gosub(connect,args(1)) then return ""
  do while TCPSTATUS(0)
    if 1<WIFIERR() and WIFIERR()<5 then return ""
    idle
  loop
  t$=""
  dim s(64)
  do
    i=TCPRECEIVE(s,256)
    poke s+i,0
    t$=t$+s$
  loop while 0<i
  TCPCLOSE
  i=gosub(gheader,t$)
  if i then t$=t$(i)
return t$

method FORBUFFER
  var b,l,t,s,i,j,k
  if 3<args(0) then pdata$=args$(4)
  if gosub(connect,args(3)) then return 0
  b=args(2) :REM Buffer
  l=args(1) :REM Buffer length
  REM Get header
  t$=""
  dim s(64)
  do
    if 1<WIFIERR() and WIFIERR()<5 then break
    i=TCPRECEIVE(s,256)
    if 0=i then
      idle
      continue
    endif
    poke s+i,0
    k=len(t$)
    t$=t$+s$
    j=gosub(gheader,t$)
    if 0=j then continue
    REM Copy after header
    i=i-j+k
    j=j-k
    do while 0<i
      if 1<WIFIERR() and WIFIERR()<5 then break
      if 0<l then
        poke b,peek(s+j)
        b=b+1:l=l-1
      endif
      i=i-1:j=j+1
    loop
    break
  loop
  REM Get remaining data during connection
  do while TCPSTATUS(0)
    if 1<WIFIERR() and WIFIERR()<5 then break
    i=TCPRECEIVE(b,l)
    if 0=i then
      idle
      continue
    endif
    b=b+i:l=l-i
  loop
  REM Get remaining data after dis-connection
  do
    if 1<WIFIERR() and WIFIERR()<5 then break
    i=TCPRECEIVE(b,l)
    if 0=i then break
    b=b+i:l=l-i
  loop
  i=TCPSTATUS(1)
  TCPCLOSE
  if i then return i+args(1)
return args(1)-l

method FORFILE
  var t,s,i,j,k
  if 2<args(0) then pdata$=args$(3)
  if gosub(connect,args(2)) then return 0
  REM Open a file
  fopen args$(1),"w"
  REM Get header
  t$=""
  dim s(64)
  do
    if 1<WIFIERR() and WIFIERR()<5 then break
    i=TCPRECEIVE(s,256)
    if 0=i then
      idle
      continue
    endif
    poke s+i,0
    k=len(t$)
    t$=t$+s$
    j=gosub(gheader,t$)
    if 0=j then continue
    REM Save after header
    fput s+j-k,i-j+k
    break
  loop
  REM Get and save remaining data during connection
  do while TCPSTATUS(0)
    if 1<WIFIERR() and WIFIERR()<5 then break
    i=TCPRECEIVE(s,256)
    if 0=i then
      idle
      continue
    endif
    fput s,i
  loop
  REM Get and save remaining data after dis-connection
  do
    if 1<WIFIERR() and WIFIERR()<5 then break
    i=TCPRECEIVE(s,256)
    if 0=i then break
    fput s,i
  loop
  TCPCLOSE
  i=flen()
  fclose
return i

method GETHEADER
  if args(0)=0 then
    if 0=header then return ""
    return header$
  endif
  var t,i,c
  REM Add ':' character
  t$=args$(1)+":"
  REM To upper cases
  for i=0 to len(t$)-1
    c=peek(t+i)
    if 0x61<=c and c<=0x7a then poke t+i,c-0x20
  next
  REM Seek ucheader$ for the name of element
  for i=0 to len(ucheader$)-1
    if 2<=i then
      if peek(ucheader+i-2)!=0x0d then continue
    endif
    if 1<=i then
      if peek(ucheader+i-1)!=0x0a then continue
    endif
    REM Reach this line in the beginning of a line. Check the name of element
    if strncmp(ucheader$(i),t$,len(t$)) then continue
    REM Found the element in header. Skip blank in the beginning
    i=i+len(t$)
    do while peek(header+i)=0x20 OR peek(header+i)=0x09
      i=i+1
    loop
    REM Prepare return string
    t$=header$(i)
    for i=0 to len(t$)-1
      if peek(t+i)!=0x0d then continue
      poke t+i,0
      break
    next
    REM All done
    return t$
  next
  return ""
return

label connect
  REM t$: initially, args$(1)
  REM u$: URI
  REM h$: host name
  REM p: port number
  REM s: TLS or not
  REM i: integer for counter
  var t,u,h,p,s,i
  REM Initializations
  t$=args$(1)
  header$=""
  ucheader=0
  REM Check protocol
  if 0=strncmp(t$,"http://",7) then
    s=0
    p=80
    t$=t$(7)
  elseif 0=strncmp(t$,"https://",8) then
    s=1
    p=443
    t$=t$(8)
  else
    print "Unknown protocol"
    return 1
  endif
  REM Check server name, port number, and URI
  u=0
  for i=0 to 253
    if peek(t+i)=asc(":") then
      h$=t$(0,i)
      p=val(t$(i+1))
      do until peek(t+i)=asc("/")
        i=i+1
      loop
      u$=t$(i)
      break
    elseif peek(t+i)=asc("/") then
      h$=t$(0,i)
      u$=t$(i)
      break
    endif
  next
  if not(u) then
    print "Invalid server name"
    return 1
  endif
  REM Send request header (+POST data)
  if pdata then
    t$="POST "+u$+" HTTP/1.0\r\n"
    t$=t$+"Connection: Close\r\n"
    t$=t$+"Accept: */*\r\n"
    t$=t$+"Host: "+h$+"\r\n"
    t$=t$+"Content-Length: "+dec$(len(pdata$))+"\r\n"
    t$=t$+"\r\n"
    t$=t$+pdata$
    pdata=0
  else
    t$="GET "+u$+" HTTP/1.0\r\n"
    t$=t$+"Connection: Close\r\n"
    t$=t$+"Accept: */*\r\n"
    t$=t$+"Host: "+h$+"\r\n"
    t$=t$+"\r\n"
  endif
  TCPSEND t$
  REM Connect to server
  if s then
    if TLSCLIENT(h$,p) then return 1
  else
    if TCPCLIENT(h$,p) then return 1
  endif
  REM Wait until connection
  do while 0=TCPSTATUS(0) and 0=TCPSTATUS(1)
    if 0<WIFIERR() and WIFIERR()<5 then return 1
    idle
  loop
return 0

label gheader
  if ucheader then return 0
  var i,c
  header$=header$+args$(1)
  for i=0 to len(t$)-5
    if peek(t+i+0)!=0x0d then continue
    if peek(t+i+1)!=0x0a then continue
    if peek(t+i+2)!=0x0d then continue
    if peek(t+i+3)!=0x0a then continue
    header$=header$(0,i+4)
    ucheader$=header$
    for i=0 to len(ucheader$)-1
      c=peek(ucheader+i)
      REM To upper case
      if 0x61<=c and c<=0x7a then poke ucheader+i,c-0x20
    next
    return len(header$)
  next
return 0
