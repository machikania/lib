REM MachiKania class WGET

static private pdata

method FORSTRING
  var t,s,i
  if 1<args(0) then pdata$=args$(2)
  if gosub(connect,args(1)) then return ""
  do while TCPSTATUS(0):idle:loop
  t$=""
  dim s(64)
  do
    i=TCPRECEIVE(s,256)
    poke s+i,0
    t$=t$+s$
  loop while 0<i
  TCPCLOSE
return t$

method FORBUFF
  rem if gosub(connect,args(3)) then return 0
return

method FORFILE
  rem if gosub(connect,args(2)) then return 0
return

label connect
  REM t$: initially, args$(1)
  REM u$: URI
  REM h$: host name
  REM p: port number
  REM s: TLS or not
  REM i: integer for counter
  var t,u,h,p,s,i
  t$=args$(1)
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
    print "https not supported yet"
    end
  else
    TCPCLIENT h$,p
  endif
  REM Wait until connection
  do while 0=TCPSTATUS(0) and 0=TCPSTATUS(1)
    idle
  loop
return
