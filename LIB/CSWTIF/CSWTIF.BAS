REM CSWTIF.BAS ver 0.1
REM Class CSWTIF for MachiKania Type M
REM for showing TIFF picture file

REM FNAME: file name
REM BENDN: if big endian data, 1
REM PX,PY: picture width and height
REM PD   : picture depth (either 4 or 8 bit)
REM SADDR: Strip offset
REM PADDR: Pointer to palette
REM P16  : Start # of 16 color palette
FIELD PRIVATE FNAME,BENDN,PX,PY,PD
FIELD PRIVATE SADDR,PADDR,P16

REM FBUFF  : file reading buffer (512 bytes)
REM FPNT   : file reading point in buffer
REM FDSIZE : valid bytes in buffer
REM SNUM   : number of strips
REM NEXTP16: Next 16 color palette
REM Txxxx : Tag information
STATIC PRIVATE FBUFF,FPNT,FDSIZE
STATIC PRIVATE SNUM,NXTP16
STATIC PRIVATE TTAG,TTYPE,TNUM,TADDR,TVAL

REM Constructor
METHOD INIT
  var i,n
  FNAME$=args$(1)
  REM Buffer size: 512 bytes
  if not(FBUFF) then dim FBUFF(127)
  fclose
  fopen FNAME$,"r"
  FDSIZE=fget(FBUFF,512)
  FPNT=0
  REM Check the header
  if 0x002a4949=FBUFF(0) then
    REM 49 49 2a 00: Intel type TIFF file (little endian)
    BENDN=0
  elseif 0x2a004d4d=FBUFF(0) then
    REM 4d 4d 00 2a: Motorola type TIFF file (big endian)
    BENDN=1
  else
    REM Format error
    goto FMTERR
  endif
  FPNT=4
  REM Read Tags address
  i=gosub(RDLONG)
  if i!=0x00000008 then
    fseek i
    FDSIZE=fget(FBUFF,512)
    FPNT=0
  endif
  REM Continue to "read tags" routine

REM Read tags
  REM Read # of tags
  n=gosub(RDSHRT)
  while n
    n=n-1
    gosub RDTAG
    if 0x100=TTAG then
      REM ImageWidth
      PX=TVAL
    elseif 0x101=TTAG then
      REM ImageLength
      PY=TVAL
    elseif 0x102=TTAG then
      REM BitsPerSample
      PD=TVAL
      if PD=8 then
        REM 256 color mode
      elseif PD=4 then
        REM 16 color mode
        NXTP16=(NXTP16+16) and 0xff
        P16=NXTP16
      else
        print "must be 256 or 16 colors"
        goto FMTERR
      endif
    elseif 0x106=TTAG then
      REM PhotometricInterpratiation
      if TVAL!=3 then
        print "palette required"
        goto FMTERR
      endif
    elseif 0x111=TTAG then
      REM StripOffsets
      SNUM=TNUM
      SADDR=TADDR
    elseif 0x140=TTAG then
      REM ColorMap
      PADDR=TADDR
    endif
  wend
  if 1<SNUM then
    REM Get first strip address
    fseek SADDR
    FDSIZE=fget(FBUFF,4)
    FPNT=0
    SADDR=gosub(RDLONG)
  endif
  REM all done
  REM close file and return
  fclose
  return

REM Private method RDTAG
REM for reading tag (total 8 bytes)
LABEL RDTAG
  gosub RFSHF
  TTAG=gosub(RDSHRT)
  TTYPE=gosub(RDSHRT)
  TNUM=gosub(RDLONG)
  TADDR=gosub(RDLONG)
  if 1=TTYPE then
    if BENDN then TVAL=TADDR>>24 else TVAL=TADDR and 0xff
  elseif 3=TTYPE then
    if BENDN then TVAL=TADDR>>16 else TVAL=TADDR and 0xffff
  elseif 4=TTYPE then
    TVAL=TADDR
  endif
  return

REM Private method FMTERR
LABEL FMTERR
  print "Not a valid TIFF file"
  end

REM Public method SHOW
METHOD SHOW
  var i,p,x,y,z
  fclose
  fopen FNAME$,"r"
  REM Read palette
  dim p(128)
  fseek PADDR
  if 8=PD then
    REM 8 bit palette
    REM red
    FDSIZE=fget(FBUFF,512):FPNT=0
    for i=0 to 255
      poke p+i,gosub(RDSHRT)>>8
    next
    REM green
    FDSIZE=fget(FBUFF,512):FPNT=0
    for i=256 to 511
      poke p+i,gosub(RDSHRT)>>8
    next
    REM blue, then palette
    FDSIZE=fget(FBUFF,512):FPNT=0
    for i=0 to 255
      palette i,peek(p+i),peek(p+256+i),gosub(RDSHRT)>>8
    next
  else
    REM 4 bit palette
    FDSIZE=fget(FBUFF,96):FPNT=0
    for i=0 to 47
      poke p+i,gosub(RDSHRT)>>8
    next
    for i=0 to 15
      palette i+P16,peek(p+i),peek(p+16+i),peek(p+32+i)
    next
  endif
  delete p
  REM Read picture
  fseek SADDR
  if 8=PD then
    REM 8 bit palette
    if PX=SYSTEM(22) then
      REM Image width is the same as graphic width
      fget SYSTEM(105)+SYSTEM(29)*PX,PX*PY
    else
      REM Image width is shorter than graphic width
      z=SYSTEM(22) :REM width of display
      p=SYSTEM(105)+z*SYSTEM(29)+SYSTEM(28) :REM Pointer to write
      FDSIZE=fget(FBUFF,512):FPNT=0
      if 256<x then
        for y=0 to PY-1
          if 256<=FPNT then gosub RFSHF
          for x=0 to 191
            poke p+x,peek(FBUFF+FPNT+x)
          next
          FPNT=FPNT+x
          if 256<=FPNT then gosub RFSHF
          for x=192 to PX-1
            poke p+x,peek(FBUFF+FPNT+x)
          next
          FPNT=FPNT+x
          p=p+z
        next
      else
        for y=0 to PY-1
          if 256<=FPNT then gosub RFSHF
          for x=0 to PX-1
            poke p+x,peek(FBUFF+FPNT+x)
          next
          FPNT=FPNT+x
          p=p+z
        next
      endif
    endif
  else
    REM 4 bit palette
    z=SYSTEM(22) :REM width of display
    p=SYSTEM(105)+z*SYSTEM(29)+SYSTEM(28) :REM Pointer to write
    FDSIZE=fget(FBUFF,512):FPNT=0
    for y=0 to PY-1
      if 256<=FPNT then gosub RFSHF
      for x=0 to PX-1
        if x and 1 then
          poke p+x,(peek(FBUFF+FPNT+(x>>1)) and 0x0f)+P16
        else
          poke p+x,(peek(FBUFF+FPNT+(x>>1)) >> 4)+P16
        endif
      next
      p=p+z
      FPNT=FPNT+((PX+1)>>1)
    next
  endif
  fclose
  return

REM Private method RFSHF
REM Refresh file buffer to maintain more than 256 bytes data
REM If file is not opened, open it.
LABEL RFSHF
  var i
  if FPNT<256 then return
  if FDSIZE<512 then return
  REM Shift 2nd 256 bytes to 1st 256 bytes area
  for i=0 to 63
    FBUFF(i)=FBUFF(i+64)
  next
  FPNT=FPNT-256
  REM Read 2nd 256 bytes from file
  FDSIZE=FDSIZE-256+fget(FBUFF+256,256)
  return

REM Private method RDLONG
REM Read big/little endian 4 byte integer
LABEL RDLONG
  var i
  if BENDN then
    i=peek(FBUFF+FPNT)<<24
    i=i or (peek(FBUFF+FPNT+1)<<16)
    i=i or (peek(FBUFF+FPNT+2)<<8)
    i=i or peek(FBUFF+FPNT+3)
  else
    i=peek(FBUFF+FPNT)
    i=i or (peek(FBUFF+FPNT+1)<<8)
    i=i or (peek(FBUFF+FPNT+2)<<16)
    i=i or (peek(FBUFF+FPNT+3)<<24)
  endif
  FPNT=FPNT+4
  return i

REM Private method RDSHRT
REM Read big/little endian 2 byte integer
LABEL RDSHRT
  FPNT=FPNT+2
  if BENDN then
    return (peek(FBUFF+FPNT-2)<<8) or peek(FBUFF+FPNT-1)
  else
    return (peek(FBUFF+FPNT-1)<<8) or peek(FBUFF+FPNT-2)
  endif

REM Private method RDBYTE
REM Read a byte
LABEL RDBYTE
  FPNT=FPNT+1
  return peek(FBUFF+FPNT-1)
