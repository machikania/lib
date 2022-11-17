REM REBOOT.BAS ver 0.1
REM Class REBOOT for MachiKania Type P
REM for rebooting Raspberry Pi Pico for program in RAM

STATIC PRIVATE C_RAM

method INIT
  gosub INIT_C
  gosub C_REBOOT,args(1)
return

LABEL INIT_C
  DIM C_RAM(4)
  REM ram vectors
  POKE32 DATAADDRESS(C_FUNCTIONS)+168,C_RAM+0
  REM rodata vectors
  REM ram function vectors
  REM callback function vectors
RETURN

ALIGN4
LABEL C_REBOOT
  EXEC $68f0,$6931,$6972,$69b3,$f000,$f802,$bd00,$46c0

REM 172 bytes
LABEL C_FUNCTIONS
EXEC $22fa,$b510,$4902,$0092,$f000,$f804,$e7fe,$46c0,$0000,$2004,$b510,$0014,$2280,$4b1b,$05d2,$601a,
     $2800,$d01a,$2301,$4a19,$4318,$4b19,$61da,$4a19,$4042,$621a,$6259,$6298,$2280,$4b13,$05d2,$601a,
     $4915,$4a16,$6011,$22e0,$04d2,$601a,$2c00,$d107,$2280,$4b13,$0612,$601a,$bd10,$4b0d,$61d8,$e7eb,
     $0163,$1b1b,$009a,$2380,$1912,$0112,$045b,$429a,$d300,$4a0c,$4b0c,$601a,$4b05,$605a,$2280,$4b08,
     $05d2,$601a,$e7e8,$46c0,$b000,$4005,$c0d3,$b007,$8000,$4005,$3f2d,$4ff8,$fffc,$0001,$2008,$4001,
     $a000,$4005,$ffff,$00ff,$05d0,$2000

REM 0 bytes
LABEL C_RODATA
