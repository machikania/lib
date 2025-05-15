REM WGET.BAS ver 0.2.0
REM MachiKania class PLAYAVI for type PU

field IMGHEIGHT,IMGWIDTH,IMGSIZE,PAGE

method INIT
  var n
  fclose
  fopen args$(1),"r"
  REM "RIFF"
  fget &n,4
  if n!=0x46464952 then CERROR
  REM Total data length (not used in this class)
  fget &n,4
  REM "AVI "
  fget &n,4
  if n!=0x20495641 then CERROR
  REM "LIST"
  fget &n,4
  if n!=0x5453494c then CERROR
  REM LIST hdrl
  fget &n,4
  n=fseek()+n
  REM start using double buffering
  usegraphic 2,1
  gosub HDRL
  fseek n
  REM "LIST"
  fget &n,4
  if n!=0x5453494c then CERROR
  REM ignore length
  fget &n,4
  REM "movi"
  fget &n,4
  if n!=0x69766f6d then CERROR
return  

label HDRL
  var n,i,p,q,d,r,g,b
  REM "hdrl"
  fget &n,4
  if n!=0x6c726468 then CERROR
  REM "avih"
  fget &n,4
  if n!=0x68697661 then CERROR
  fget &n,4
  fseek fseek()+n
  REM "LIST"
  fget &n,4
  if n!=0x5453494c then CERROR
  fget &n,4
  REM "strl"
  fget &n,4
  if n!=0x6c727473 then CERROR
  REM "strh"
  fget &n,4
  if n!=0x68727473 then CERROR
  fget &n,4
  fseek fseek()+n
  REM "strf"
  fget &n,4
  if n!=0x66727473 then CERROR
  REM 1064
  fget &n,4
  if n!=1064 then CERROR
  REM 40
  fget &n,4
  if n!=40 then CERROR
  REM widh must be less than 337
  fget &n,4
  if n<1 or 336<n then
    print
    print "Maximum IMGWIDTH is 336";
    goto CERROR
  endif
  IMGWIDTH=n
  REM height must be less than 217
  fget &n,4
  if n<1 or 216<n then
    print
    print "Maximum height is 216";
    goto CERROR
  endif
  IMGHEIGHT=n
  IMGSIZE=IMGWIDTH*IMGHEIGHT
  fseek fseek()+40-4-4-4
  REM Get palette
  REM d: darkest palette color
  REM p: darkest palette number
  REM q: palette of number 0
  d=256*3
  fget &q,4
  for i=1 to 255
    fget &n,4
    r=(n>>16) and 255
    g=(n>>8) and 255
    b=n and 255
    if r+g+b<((d>>16) and 255)+((d>>8) and 255)+(d and 255) then
      d=n
      p=i
    endif
    gpalette i, r, g, b
  next
  REM set palette 0 and clear two gvrams
  r=(q>>16) and 255
  g=(q>>8) and 255
  b=q and 255
  boxfill 0,0,335,215,p
  gpalette 0,r,g,b
  usegraphic 3,2
  boxfill 0,0,335,215,p
  PAGE=2
return

method PLAY
  if 336=IMGWIDTH then PLAY336
  var n,b,i,s
  REM show the previously prepared image, first
  PAGE=3-PAGE
  usegraphic 3,PAGE
  REM b: buffer address to start image
  b=SYSTEM(105)+((215-IMGHEIGHT)>>1)*336+((336-IMGWIDTH)>>1)
  REM "00db"
  fget &n,4
  if 0x62643030=n then
    REM length
    fget &n,4
    if n<IMGSIZE then CERROR
    REM determine skip byte(s) number
    s=n/IMGHEIGHT - IMGWIDTH
    for i=1 to IMGHEIGHT
      REM get the image from file
      fget b,IMGWIDTH
      b=b+336
      if 0<s then fseek fseek()+s
    next
  elseif 0x31786469=n then
    REM "idx1"
    REM end of movie
    fclose
    return 0
  else
    goto CERROR
  endif
return 1
  

label PLAY336
  var n,b,i
  REM show the previously prepared image, first
  PAGE=3-PAGE
  usegraphic 3,PAGE
  REM b: buffer address to start image
  b=SYSTEM(105)+(215-IMGHEIGHT)/2*336
  REM "00db"
  fget &n,4
  if 0x62643030=n then
    REM length
    fget &n,4
    REM get the image from file
    if n=IMGSIZE then
      fget b,n
    elseif IMGSIZE<n then
      fget b,IMGSIZE
      fseek fseek()+n-IMGSIZE
    else
      goto CERROR
    endif
  elseif 0x31786469=n then
    REM "idx1"
    REM end of movie
    fclose
    return 0
  else
    goto CERROR
  endif
return 1

label CERROR
  print
  print "AVI file error at around position ";fseek()-4
  fclose
  end
