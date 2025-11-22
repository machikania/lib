REM FFTLIB class
REM Referenced Okumura's FFT library
REM https://github.com/okumuralab/algo-c/blob/main/src/fft.c

REM Constructor
REM F=NEW(FFTLIB,N)
REM N:The number of samples(8,16,32...)

REM Public field
REM RE#():Real numbers array
REM IM#():Imagenary numbers array

REM Method FFT(R,I)
REM Execute Fast Fourier Transformation
REM R:Real numbers array (float)
REM I:Imagenary numbers array (float)
REM  I=0:Clear IM#() array field
REM  I=1:Use previous IM# array field
REM  I=Other:Specify Imaginary array
REM Return:RE# and IM# array field

REM Method IFFT(R,I)
REM Execute inverce Fast Fourier Transformation
REM R,I:Same as FFT method

REM Notice: Since array fileds cannot be used outside the library, assign RE and IM array fields to other pointer variables in the calling routine.

REM Usage example
REM F=NEW(FFTLIB,N)
REM DIM R(N-1),I(N-1)
REM  Data sampling here
REM  R#(x)=...:I#(x)=...
REM F.FFT(R,I)
REM P=F.RE:Q=F.IM
REM FOR J=0 TO N-1
REM  PRINT P#(J),Q#(J)
REM NEXT

FIELD PUBLIC RE,IM
FIELD PRIVATE NUM,SINTBL,BITREV

METHOD INIT
 VAR I,J,K,L,M,N,T,A,B,C,S
 NUM=ARGS(1)
 I=4
 DO
  IF NUM=I THEN BREAK
  I=I<<1
  IF I<0 THEN
   PRINT "Sample number error":END
  ENDIF
 LOOP

 DIM SINTBL(NUM-1),BITREV(NUM-1)
 DIM RE(NUM-1),IM(NUM-1)

 REM Make sine table
 L=NUM/2:M=NUM/4:N=NUM/8
 T#=SIN#(PI#/FLOAT#(NUM))
 A#=2.0*T#*T#
 B#=SQRT#(A#*(2.0-A#))
 T#=2.0*A#
 C#=1:SINTBL#(M)=1
 S#=0:SINTBL#(0)=0
 FOR I=1 TO N-1
  C#=C#-A#:A#=A#+T#*C#
  S#=S#+B#:B#=B#-T#*S#
  SINTBL#(I)=S#:SINTBL#(M-I)=C#
 NEXT
 IF N!=0 THEN SINTBL#(N)=SQRT#(0.5)
 FOR I=0 TO M-1
  SINTBL#(L-I)=SINTBL#(I)
  SINTBL#(I+L)=-SINTBL#(I)
 NEXT

 REM Make bit reverse table
 I=0:J=0
 DO
  BITREV(I)=J
  I=I+1:IF I>=NUM THEN BREAK
  K=L
  DO WHILE K<=J
   J=J-K:K=K/2
  LOOP
  J=J+K
 LOOP
RETURN

METHOD FFT
 VAR I,J,K,L,H,D,M,N,T,S,C,X,Y
 T=ARGS(1)
 FOR I=0 TO NUM-1:RE#(I)=T#(I):NEXT
 IF ARGS(2)=0 THEN
  FOR I=0 TO NUM-1:IM#(I)=0:NEXT
 ELSEIF ARGS(2)!=1 THEN
  T=ARGS(2)
  FOR I=0 TO NUM-1:IM#(I)=T#(I):NEXT
 ENDIF
 N=NUM/4
 FOR I=0 TO NUM-1
  J=BITREV(I)
  IF I<J THEN
   T#=RE#(I):RE#(I)=RE#(J):RE#(J)=T#
  ENDIF
 NEXT
 K=1
 DO WHILE K<NUM
  H=0:M=K+K:D=NUM/M
  FOR J=0 TO K-1
   C#=SINTBL#(H+N)
   S#=SINTBL#(H)
   I=J
   DO WHILE I<NUM-1
    L=I+K
    X#=S#*IM#(L)+C#*RE#(L)
    Y#=C#*IM#(L)-S#*RE#(L)
    RE#(L)=RE#(I)-X#:RE#(I)=RE#(I)+X#
    IM#(L)=IM#(I)-Y#:IM#(I)=IM#(I)+Y#
    I=I+M
   LOOP
   H=H+D
  NEXT
  K=M
 LOOP
 T#=FLOAT#(NUM)
 FOR I=0 TO NUM-1
  RE#(I)=RE#(I)/T#
  IM#(I)=IM#(I)/T#
 NEXT
RETURN

METHOD IFFT
 VAR I,J,K,L,H,D,M,N,T,S,C,X,Y
 T=ARGS(1)
 FOR I=0 TO NUM-1:RE#(I)=T#(I):NEXT
 IF ARGS(2)=0 THEN
  FOR I=0 TO NUM-1:IM#(I)=0:NEXT
 ELSEIF ARGS(2)!=1 THEN
  T=ARGS(2)
  FOR I=0 TO NUM-1:IM#(I)=T#(I):NEXT
 ENDIF
 N=NUM/4
 FOR I=0 TO NUM-1
  J=BITREV(I)
  IF I<J THEN
   T#=RE#(I):RE#(I)=RE#(J):RE#(J)=T#
   T#=IM#(I):IM#(I)=IM#(J):IM#(J)=T#
  ENDIF
 NEXT
 K=1
 DO WHILE K<NUM
  H=0:M=K+K:D=NUM/M
  FOR J=0 TO K-1
   C#=SINTBL#(H+N)
   S#=-SINTBL#(H)
   I=J
   DO WHILE I<NUM-1
    L=I+K
    X#=S#*IM#(L)+C#*RE#(L)
    Y#=C#*IM#(L)-S#*RE#(L)
    RE#(L)=RE#(I)-X#:RE#(I)=RE#(I)+X#
    IM#(L)=IM#(I)-Y#:IM#(I)=IM#(I)+Y#
    I=I+M
   LOOP
   H=H+D
  NEXT
  K=M
 LOOP
RETURN
