REM TBUTTON ver 0.2
REM Class TBUTTON for MachiKania Type P

static private objects, objNum, touchX, touchY, touchObj, ii, oo
field posX, posY, rWidth, rHeight, tCallback, rCallback, cbArg

rem x, y, w, h, touch_callback[, release_callback[, callback_argument]]
method INIT
  rem Update objects()
  if 0=objects then
    dim objects(objNum)
  else
    dim oo(objNum)
    for ii=0 to objNum-1
      oo(ii)=objects(ii)
    next
    dim objects(objNum)
    for ii=0 to objNum-1
      objects(ii)=oo(ii)
    next
    delete oo
  endif
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
method touch
  rem If not yet released, return
  if touchObj then return
  rem This is a new touch event. Let's find a TBUTTON object that is pressed
  rem Do not use "var" statement here as it will call the callback function
  touchX=args(1)
  touchY=args(2)
  for ii=0 to objNum-1
    oo=objects(ii)
    if touchX<oo.posX then continue
    if touchY<oo.posY then continue
    if oo.posX+oo.rWidth<=touchX then continue
    if oo.posY+oo.rHeight<=touchY then continue
    touchObj=oo
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

rem args(1): callback_argument
rem args(2): touch X
rem args(3): touch Y
rem args(4): button X
rem args(5): button Y
rem args(6): button width
rem args(7): button height
rem args(8): callback address
label callback
rem A "GOTO" statement to the address of args(8)
rem 0x6ab0: LDR     R0, [R6, #40]
rem 0x4700: BX      R0
rem 0xbf00: NOP
exec 0x6ab0, 0x4700, 0xbf00
