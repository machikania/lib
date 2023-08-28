REM Class HTTPD ver 0.1

static private homedir,portnum,mime,cid,fname
static public URI,RHEADER,STATUS,GPARAMS

method INIT
  var i,d
  REM Set port number
  if 0<args(0) then
    portnum=args(1)
  else
    portnum=80
  endif
  REM Set home directory
  if 1<args(0) then
    homedir$=args$(2)
  else
    homedir$=getdir$()
  endif
  if 0=strncmp(homedir$(-1),"/",1) then homedir$=homedir$(0,len(homedir$)-1)
  REM Get mime data
  i=0
  d$=getdir$()
  setdir "/lib/httpd/"
  fopen "mime.txt","r"
  mime$=""
  do until feof()
    mime$=mime$+finput$()
  loop
  fclose
  setdir d$
  REM Start server
  TCPSERVER portnum
return

method LASTURI
  return URI$

method START
  REM s: read buffer
  REM d: current directry
  REM i: temporary integer
  var s,d,i
  URI$=""
  GPARAMS$=""
  d$=getdir$()
  REM Connection-waiting loop follows
  do
    REM Wait for request
    delayms 10
    cid=TCPACCEPT()
  loop until cid
  delayms 10
  REM Read request header
  RHEADER$=""
  dim s(64)
  do
    i=TCPRECEIVE(s,256,cid)
    poke s+i,0
    RHEADER$=RHEADER$+s$
  loop while 0<i
  REM Check method
  if 0=strncmp(RHEADER$,"GET ",4) then
    if gosub(openfile,4) then
      gosub sendheader
      gosub sendbody
      STATUS=200
    else
      gosub error404
      STATUS=404
    endif
  elseif 0=strncmp(RHEADER$,"HEAD ",5) then
    if gosub(openfile,5) then
      gosub sendheader
      STATUS=200
    else
      gosub error404
      STATUS=404
    endif
  else
    URI$=""
    gosub error403
    STATUS=403
  endif
  REM Wait for a while to send all data
  delayms 10
  REM All done. Close connection (Connection: close)
  TCPCLOSE cid
  setdir d$
return URI$

label error403
  var t
  t$="HTTP/1.0 403 Method Not Allowed\r\n"
  t$=t$+"Content-Type: text/html\r\n"
  t$=t$+"Content-Length: 48\r\n"
  t$=t$+"Connection: close\r\n"
  t$=t$+"\r\n"
  t$=t$+"<html><body>403 Method Not Allowed</body></html>"
  TCPSEND t$,len(t$),cid
return

label error404
  var t
  t$="HTTP/1.0 404 Not Found\r\n"
  t$=t$+"Content-Type: text/html\r\n"
  t$=t$+"Content-Length: 39\r\n"
  t$=t$+"Connection: close\r\n"
  t$=t$+"\r\n"
  t$=t$+"<html><body>404 Not Found</body></html>"
  TCPSEND t$,len(t$),cid
return

label getmime
  REM args$(1): extension string
  var l,e,i,j
  e$=args$(1)+" "
  i=0
  do while peek(mime+i)
    j=i
    do until peek(mime+j)<0x20 : j=j+1 : loop
    l$=mime$(i,j-i)
    do while 0x0d=peek(mime+j) OR 0x0a=peek(mime+j) : j=j+1 : loop
    i=j
    if strncmp(l$,e$,len(e$)) then continue
    l$=l$(len(e$))
    do while 0x20=peek(l): l$=l$(1) : loop
    break
  loop
  if 0=peek(mime+i) then l$="application/octet-stream"
return l$

label openfile
  var i,d,f
  REM Construct URI
  i=args(1)
  do while 0x20!=peek(RHEADER+i) : i=i+1 : loop
  URI$=RHEADER$(args(1),i-args(1))
  REM Construct full path to file (ignore ? and later characters)
  d$=homedir$+URI$
  i=0
  do while peek(d+i)
    if 0x3f==peek(d+i) then
      REM '?' found
      GPARAMS$=d$(i)
      poke d+i,0
      break
    endif
    i=i+1
  loop
  REM Divide to directory path and file name
  i=0
  f=0
  do while peek(d+i)
    if 0x2f=peek(d+i) then f=i+1 : REM "/"
    i=i+1
  loop
  REM Set current directory
  if setdir(d$(0,f)) then return 0
  REM Open file
  if 0=peek(d+f) then
    fname$="index.htm"
  else
    fname$=d$(f)
  endif
return fopen(fname$,"r")

label sendheader
  var t,i,m
  REM Get Mime
  i=0
  m=0
  do while peek(fname+i)
    if 0x2e=peek(fname+i) then m=i+1 : REM "."
    i=i+1
  loop
  if 0<m then
    m$=fname$(m)
    m$=gosub$(getmime,m)
  else
    m$="application/octet-stream"
  endif
  t$="HTTP/1.0 200 OK\r\n"
  t$=t$+"Content-Type: "+m$+"\r\n"
  t$=t$+"Content-Length: "+dec$(flen())+"\r\n"
  t$=t$+"Connection: close\r\n"
  t$=t$+"\r\n"
  TCPSEND t$,len(t$),cid
return

label sendbody
  var b,i
  dim b(127)
  do until feof()
    REM Get data from file
    i=fget(b,512)
    REM Send data to TCP client
    TCPSEND b,i,cid
  loop
return

method GETPARAM
  REM p: parameter name (and return string)
  REM i: counter
  REM l: text length
  REM c: character
  var i,p
  if args(0)<1 then return GPARAMS$
  l=len(GPARAMS$)
  REM Find the parameter from name
  p$=args$(1)+"="
  REM Explore GPARAMS
  i=0
  do while i<l
    REM Seek '?' or '&'
    c=peek(GPARAMS+i) : i=i+1
    if 0x3f!=c and 0x26!=c then continue
    REM Check parameter name
    if strncmp(p$,GPARAMS$(i),len(p$)) then continue
    REM Parameter name found
    i=i+len(p$)
    p$=""
    c=peek(GPARAMS+i)
    do until 0x26=c or 0=c
      if c=0x25 then
        REM '%'
        p$=p$+chr$(val("$"+GPARAMS$(i+1,2)))
        i=i+3
      elseif c=0x2b then
        REM '+'
        p$=p$+" "
        i=i+1
      else
        p$=p$+chr$(c)
        i=i+1
      endif
      c=peek(GPARAMS+i)
    loop
    return p$
  loop
  REM Parameter name not found
return ""
