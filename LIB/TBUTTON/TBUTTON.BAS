REM TBUTTON ver 0.1
REM Class TBUTTON for MachiKania Type P

static private objects, objNum, touchX, touchY, touchObj
field posX, posY, rWidth, rHeight, tCallback, rCallback, cbArg

rem x, y, w, h, touch_callback[, release_callback[, callback_argument]]
method INIT
  rem Update objects()
  if 0=objects then dim objects(20)
  objects(objNum)=args(-2)
  objNum=objNum+1
  rem Create a TBUTTON object  
  posX=args(1)
  posY=args(2)
  rWidth=args(3)
  rHeight=args(4)
  tCallback=args(5)
  if 5<args(0) then rCallback=args(6)
  if 6<args(0) then cbArg=args(7)
return

rem touch x, y
method touched
  rem If not yet released, return
  if touchObj then return
  rem This is a new touch event. Let's find a TBUTTON object that is pressed
  var i,o
  touchX=args(1)
  touchY=args(2)
  for i=0 to objNum-1
    o=objects(i)
    if touchX<o.posX then continue
    if touchY<o.posY then continue
    if o.posX+o.rWidth<=touchX then continue
    if o.posY+o.rHeight<=touchY then continue
    touchObj=o
    break
  next
  if 0=touchObj then return
  rem The TBUTTON object found. Call the call-back function
  gosub callback, touchObj.cbArg, touchX, touchY, touchObj.posX, touchObj.posY, touchObj.rWidth, touchObj.rHeight, touchObj.tCallback
return

rem release event
method release
  if 0=touchObj then return
  if 0=touchObj.rCallback then return
  gosub callback, touchObj.cbArg, touchX, touchY, touchObj.posX, touchObj.posY, touchObj.rWidth, touchObj.rHeight, touchObj.rCallback
  touchObj=0
return

label callback
rem A "GOTO" statement to the address of args(8)
rem 0x6ab0: LDR     R0, [R6, #40]
rem 0x4700: BX      R0
rem 0xbf00: NOP
exec 0x6ab0, 0x4700, 0xbf00
