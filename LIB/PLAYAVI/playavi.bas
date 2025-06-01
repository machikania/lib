REM PLAYAVI.BAS ver 0.3.1
REM MachiKania class PLAYAVI for type PU

usevar IMGHEIGHT,IMGWIDTH,IMGSIZE,PAGE
usevar WAVEBUFFER,WBPOS,WBREADPOS

rem Constructor
rem 1st argument: AVI file name

method INIT
  var n
  delete WAVEBUFFER
  file 1
  fclose 1
  fopen args$(1),"r",1
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

rem SETWAVE method may be called for a movie with audio
rem Set the file name of a WAV file as the 1st argument
rem The WAVE file must contain monaural 8 bit PCM audio data without compression
rem The audio sample rate must be 15874 Hz
rem The AVI fps must be 15 fps for using audio
rem The buffer size is 1055 bytes for one AVI image (15 fps)

method SETWAVE
  var i
  rem Set WAVE mode PWM
  PLAYWAVE args$(1) : PLAYWAVE ""
  rem Prepare buffer and fill it with 0x80
  dim WAVEBUFFER(527) :rem 1055*2/4 -1 = 526.5
  for i=0 to 527
    WAVEBUFFER(i)=0x80808080
  next
  rem Open WAVE file and read header
  file 2
  fclose 2
  fopen args$(1),"r",2
  fget WAVEBUFFER,128
  rem Note that the format of WAVE file was checked by PLAYWAVE statement above
  rem Seek "data"
  for i=0x2c to 128
    rem (i-8): skip "data" and length chunk
    if 0x64!=peek(WAVEBUFFER+i-8) then continue
    if 0x61!=peek(WAVEBUFFER+i-7) then continue
    if 0x74!=peek(WAVEBUFFER+i-6) then continue
    if 0x61!=peek(WAVEBUFFER+i-5) then continue
    break
  next
  fseek i
  WBPOS=1055
  WBREADPOS=0
  file 1
  rem Set call back function
  interrupt timer,tcallback
return

rem PLAY method must be called periodically
rem When using 15 fps AVI file, this must be called in 15 Hz 

method PLAY
  if 336=IMGWIDTH then PLAY336
  var n,b,i,s
  REM show the previously prepared image, first
  PAGE=3-PAGE
  usegraphic 3,PAGE
  REM Play WAVE if exists
  if WAVEBUFFER then gosub PLAYWV
  REM b: buffer address to start image
  b=SYSTEM(105)+((215-IMGHEIGHT)>>1)*336+((336-IMGWIDTH)>>1)
  REM "00db"
  file 1
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
    fclose 1
    if WAVEBUFFER then
      delete WAVEBUFFER
      fclose 2
    endif
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
  REM Play WAVE if exists
  if WAVEBUFFER then gosub PLAYWV
  REM b: buffer address to start image
  b=SYSTEM(105)+(215-IMGHEIGHT)/2*336
  REM "00db"
  file 1
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
    fclose 1
    if WAVEBUFFER then
      delete WAVEBUFFER
      fclose 2
    endif
    return 0
  else
    goto CERROR
  endif
return 1

label PLAYWV
  if 0<WBPOS then
    rem Set timer
    usetimer 63: rem 15873 Hz
    WBREADPOS=0
  endif
  file 2
  fget WAVEBUFFER+WBPOS,1055
  WBPOS=1055-WBPOS
  file 1
return

label tcallback
  if 0=WAVEBUFFER then
    interrupt stop timer
    return
  endif
  rem pwm_set_chan_level(AUDIO_SLICE, AUDIO_CHAN, (unsigned char)r0);
  peek(WAVEBUFFER+WBREADPOS)
  align4
  exec $4603,$4905,$b2db,$f8d1,$1084,$4a04,$404b,$b29b
  exec $f8c2,$3084,$e004,$bf00,$8000,$400a,$9000,$400a
  WBREADPOS=WBREADPOS+1
return

method MOVEAVIPOINTER
  var n
  file 1
  fget &n,4
  if 0x62643030!=n then CERROR
  fget &n,4
  fseek fseek()-8+args(1)*(n+8)
return

method MOVEWAVPOINTER
  file 2
  fseek fseek()+args(1)
  file 1
return

label CERROR
  print
  print "AVI file error at around position ";fseek()-4
  fclose
  end
