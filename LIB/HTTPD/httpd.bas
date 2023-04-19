REM Class HTTPD

static private homedir,portnum,mime
static public URI,RHEADER,STATUS

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
return

method LASTURI
  return URI$

method START
  REM s: read buffer
  REM d: current directry
  var s,d
  d$=getdir$()
  REM Start server
  TCPSERVER portnum
  REM Wait for request

print "Server started"
print "WIFIERR=";WIFIERR()
print "WIFIERR$=";WIFIERR$()

  do until TCPSTATUS(1) : idle : loop

print "Request received"

  REM Read request header
  RHEADER$=""
  dim s(64)
  do
    i=TCPRECEIVE(s,256)
    poke s+i,0
    RHEADER$=RHEADER$+s$
  loop while 0<i
  REM Check method
  if 0=strncmp(RHEADER$,"GET ",4) then
    if gosub(openfile,4) then
      gosub sendheader
      gosub sendbody
      fclose
      STATUS=200
    else
      gosub error404
      STATUS=404
    endif
  elseif 0=strncmp(RHEADER$,"HEAD ",5) then
    if gosub(openfile,5) then
      gosub sendheader
      fclose
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
  REM Wait until all data will be sent
  do while TCPSTATUS(2) : idle : loop
  REM All done. Close connection (Connection: close)
  TCPCLOSE
  setdir d$
  wait 20
return URI$

label error403
  var t
  t$="HTTP/1.0 403 Method Not Allowed\r\n"
  t$=t$+"Content-Type: text/html\r\n"
  t$=t$+"Content-Length: 48\r\n"
  t$=t$+"Connection: close\r\n"
  t$=t$+"\r\n"
  t$=t$+"<html><body>403 Method Not Allowed</body></html>"
  TCPSEND(t$)
return

label error404
  var t
  t$="HTTP/1.0 404 Not Found\r\n"
  t$=t$+"Content-Type: text/html\r\n"
  t$=t$+"Content-Length: 39\r\n"
  t$=t$+"Connection: close\r\n"
  t$=t$+"\r\n"
  t$=t$+"<html><body>404 Not Found</body></html>"
  TCPSEND(t$)
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
  i=args(1)
  do while 0x20!=peek(RHEADER+i) : i=i+1 : loop
  URI$=RHEADER$(args(1),i-args(1))
  d$=homedir$+URI$
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
    return fopen("index.htm","r")
  else
    return fopen(d$(f),"r")
  endif

label sendheader
  var t,i,m
  REM Get Mime
  i=0
  m=0
  do while peek(URI+i)
    if 0x2e=peek(URI+i) then m=i+1 : REM "."
    i=i+1
  loop
  if 0<m then
    m$=gosub$(getmime,URI$(m))
  elseif 1=i then
    m$="text/html"
  else
    m$="application/octet-stream"
  endif
  t$="HTTP/1.0 200 OK\r\n"
  t$=t$+"Content-Type: "+m$+"\r\n"
  t$=t$+"Content-Length: "+dec$(flen())+"\r\n"
  t$=t$+"Connection: close\r\n"
  t$=t$+"\r\n"
  TCPSEND t$
  do while TCPSTATUS(2) : idle : loop
return

label sendbody
  var b,i
  dim b(511)
  do until feof()
    REM Get data from file
    i=fget(b,2048)
    REM Wait until all data remaining will be sent
    do while TCPSTATUS(2) : idle : loop
    REM Send data to TCP client
    TCPSEND b,i
  loop
return
