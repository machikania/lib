REM CST816D ver 0.3
REM Class CST816D for MachiKania Type P, especially for RP2350-Touch-LCD-2

field Touch, Xpos, Ypos
static private LCDTURN

method INIT
  var t
  t=system(2)
  if val(t$(3))<1512 then
    print "KM-1512 or later version is required"
    end
  endif
  LCDTURN=system(30)
  if 0<args(0) then
    I2C args(1)
  else
    I2C 400
  endif
return

rem CST816D registers
rem CST816_FingerNum = 0x02
rem CST816_XposL     = 0x04
rem CST816_YposH     = 0x05
rem CST816_YposL     = 0x06

rem When reading I2C data at &x+1
rem 
rem X    Y    (registers)
rem  +----+   (read by I2C; 5 bytes)
rem 0123 0123 (address)
rem  | | ||
rem  | | |+-- YposL
rem  | | +--- YposH
rem  | +----- XposL
rem  +------- FingerNum
method POLLING
  rem The resisters x,y are both used to read 5 bits data
  var x,y
  I2CREADDATA 0x15,&x+1,5,0x02
  Touch=(x>>8) and 0xff
  if 0=LCDTURN then
    Ypos=239-(x>>24)
    Xpos=(y>>8) or ((y and 0xff)<<8)
  elseif 180=LCDTURN then
    Ypos=x>>24
    Xpos=319-((y>>8) or ((y and 0xff)<<8))
  elseif 270=LCDTURN then
    Xpos=x>>24
    Ypos=(y>>8) or ((y and 0xff)<<8)
  else
    Xpos=239-(x>>24)
    Ypos=319-((y>>8) or ((y and 0xff)<<8))
  endif
return Touch
