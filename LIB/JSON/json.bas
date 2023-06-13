REM JSON.BAS ver 0.1
REM Class JSON for MachiKania Type P/M/Z 

REM Field
REM   JTEXT$:  JSON text
field JTEXT

REM Static field (used temporarily)
REM   JBEGIN:  begin point of JSON text interested in
REM   JEND:    end point of JSON text interested in
REM   QTEXT$:  Query string
REM   RET$:    Return string
usevar JBEGIN,JEND,QTEXT,RET

REM Local variables
REM   c: character
REM   i: general purpose integer
REM   n: number or name
REM   q: pointer to QTEXT$
REM   e: temporarily stored JEND value
REM   d: depth of nest

method INIT
	JTEXT$=args$(1)
return

method QUERY
	QTEXT$=args$(1)
	gosub QMAIN
	RET$=JTEXT$(JBEGIN,JEND-JBEGIN)
return RET$

method SQUERY
	QTEXT$=args$(1)
	gosub QMAIN
	RET$=JTEXT$(JBEGIN,JEND-JBEGIN)
	RET$=gosub$(DECODE,RET$)
return RET$

method IQUERY
	QTEXT$=args$(1)
	gosub QMAIN
	RET$=JTEXT$(JBEGIN,JEND-JBEGIN)
	if 0=strncmp(RET$,"true",4) then return 1
return val(RET$)

method FQUERY
	QTEXT$=args$(1)
	gosub QMAIN
	RET$=JTEXT$(JBEGIN,JEND-JBEGIN)
return val#(RET$)

label QMAIN
	var c,i,n,q,e,d
	JBEGIN=0
	JEND=len(JTEXT$)
	q=QTEXT
	do
		c=peek(q)
		if 0=c then return
		if 0x5b=c then
			REM 0x5b: [
			n=val(q$(1))
			i=0
			do
			  i=i+1
			  c=peek(q+i)
			loop until c=0x5d : REM 0x5d: ]
			q=q+i+1
			gosub ARRAYM
		elseif 0x2e=c then
			REM 0x2e: .
			i=0
			do
			  i=i+1
			  c=peek(q+i)
			loop until c=0x5b or c=0x2e or 0=c : REM 0x5b: [, 0x2e: .
			n$=q$(1,i-1)
			q=q+i
			gosub OBJM
		else
			print "\nJSON query syntax error:"
			print q$
			end
		endif
	loop

REM Get an array member
REM n: number of index in array
label ARRAYM
	gosub SKIPB
	if c!=0x5b then goto NFOUND : REM 0x5b: [
	JBEGIN=JBEGIN+1
	for i=1 to n
		gosub SKIPAV
		gosub SKIPB
		if c!=0x2c then goto NFOUND : REM 0x2c: ,
		JBEGIN=JBEGIN+1
	next
	gosub GETAV
return

REM Get an object member
REM n$: field name
label OBJM
	gosub SKIPB
	if c!=0x7b then goto NFOUND : REM 0x7b: {
	JBEGIN=JBEGIN+1
	do
		gosub SKIPB
		if c!=0x22 then goto JERR : REM 0x22: "
		if strncmp(JTEXT$(JBEGIN+1),n$,len(n$)) or 0x22!=peek(JTEXT+JBEGIN+len(n$)+1) then
			REM Not match. Skip
			gosub SKIPAV
			gosub SKIPB
			if c!=0x3a then goto JERR : REM 0x3a: :
			JBEGIN=JBEGIN+1
			gosub SKIPAV
			gosub SKIPB
			if c!=0x2c then goto NFOUND : REM 0x2c: ,
			JBEGIN=JBEGIN+1
			continue
		else
			REM Object member found
			gosub SKIPAV
			gosub SKIPB
			if c!=0x3a then goto JERR : REM 0x3a: :
			JBEGIN=JBEGIN+1
			gosub GETAV
			return
		endif
	loop

REM Skip a value
label SKIPAV
	e=JEND
	gosub GETAV
	JBEGIN=JEND
	JEND=e
return

REM Get a value
REM All the variables used inside must be stored in stack: i,e,c
label GETAV
	var i,e,c
	gosub SKIPB
	if 0x22=c then
		REM 0x22: "
		gosub GASTR
	elseif 0x5b=c then
		REM 0x5b: [
		gosub GANAO,0x5b
	elseif 0x7b=c then
		REM 0x7b: {
		gosub GANAO,0x7b
	elseif 0x6e=c then
		REM 0x6e: n
		if strncmp(JTEXT$(JBEGIN),"null",4) then goto JERR
		JEND=JBEGIN+4
	elseif 0x74=c then
		REM 0x74: t
		if strncmp(JTEXT$(JBEGIN),"true",4) then goto JERR
		JEND=JBEGIN+4
	elseif 0x66=c then
		REM 0x66: f
		if strncmp(JTEXT$(JBEGIN),"false",5) then goto JERR
		JEND=JBEGIN+5
	elseif 0x30<=c and c<=0x39 or 0x2e=c or 0x2d=c then
		REM 0x30: 0, 0x39: 9, 0x2e: ., 0x2b: +, 0x2d: -, 0x45: E, 0x65: e
		for i=JBEGIN to JEND-1
			c=peek(JTEXT+i)
			if 0x30<=c and c<=0x39 or 0x2e=c or 0x2b=c or 0x2d=c or 0x45=c or 0x65=c then continue
			break
		next
		JEND=i
	else
		goto JERR
	endif
return

REM Get an array or object
REM parameter1=0x5b ([): array
REM parameter1=0x7b ({): object
label GANAO
	var i,d,e
	d=0
	for i=JBEGIN to JEND-1
		c=peek(JTEXT+i)
		if args(1)=c then
			REM 0x5b: [
			REM 0x7b: {
			d=d+1
		elseif args(1)+2=c then
			REM 0x5d: ]
			REM 0x7d: }
			d=d-1
			if 0=d then
				i=i+1
				break
			endif
		elseif 0x22=c then
			REM 0x22: "
			do
				i=i+1
				c=peek(JTEXT+i)
				if 0x22=c then
					REM 0x22: "
					break
				elseif c=0x5c then
					REM 0x5c: \
					i=i+1
				endif
			loop
		endif
	next
	JEND=i
return

REM Get a string
REM Note that '"' will be included at both left and right
label GASTR
	gosub SKIPB
	if 0x22!=c then
		REM 0x22: "
		goto JERR
	endif
	for i=JBEGIN+1 to JEND-1
		c=peek(JTEXT+i)
		if 0x22=c then
			i=i+1
			break
		elseif c=0x5c then
			REM 0x5c: \
			i=i+1
		endif
	next
	JEND=i
return

REM Decode string
label DECODE
	var t,c,i
	t$=args$(1)
	RET$=""
	c=peek(t)
	if 0x22!=c then return t$
	i=1
	do
		c=peek(t+i)
		if 0x22=c or 0=c then
			return RET$
		elseif c=0x5c then
			REM 0x5c: \
			c=peek(t+i+1)
			if 0x62=c then
				REM 0x62: b
				c=0x08
			elseif 0x66=c then
				REM 0x66: f
				c=0x0c
			elseif 0x6e=c then
				REM 0x6e: n
				c=0x0a
			elseif 0x72=c then
				REM 0x72: r
				c=0x0d
			elseif 0x74=c then
				REM 0x74: t
				c=0x09
			elseif 0x75=c then
				REM 0x75: u
				c=0x55 : REM 0x55: U
			endif
			RET$=RET$+chr$(c)
			i=i+2
		else
			RET$=RET$+chr$(c)
			i=i+1
		endif
	loop

REM Skip blank
REM c will be character at JBEGIN
label SKIPB
	do
		c=peek(JTEXT+JBEGIN)
		if 0x20<c then break
		JBEGIN=JBEGIN+1
	loop
return

REM Not found error
label NFOUND
	print
	print QTEXT$(0,q-QTEXT);" not found in JSON"
	end

REM JASON syntax error
label JERR
	print
	print "JSON syntax error:"
	print JTEXT$(JBEGIN,10)
	end
