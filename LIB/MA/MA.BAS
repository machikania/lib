REM MA class
REM ver 0.1

field public memadr

rem Constructor
method INIT
  REM check KM-BASIC version
  var v
  v=system(2)
  v=val(v$(3))
  if v<=1200 AND v<1208 or 1300<=v AND v<1303 or 1500<=v AND v<1501 then
    print "Latest version of KM-BASIC is required"
    end
  endif
  REM check argument
  if args(0)<1 then
    print "An argument is requred as byte size"
    end
  endif
  REM allocate memory
  if 0<args(1) then dim memadr(((args(1)+3)>>2)-1)
return
