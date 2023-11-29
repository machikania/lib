<?php

/*
	This program is provided under the LGPL license ver 2.1
	c_convert2.php ver 0.1, written by Katsumi.
	https://github.com/kmorimatsu
*/

/*
	Configuration
*/

class configclass{
	// File names
	public $dis_file='./build/QRCODE10.dis';
	public $map_file='./build/QRCODE10.elf.map';
	public $hex_file='./build/QRCODE10.hex';
	public $debug_file='./machikap/machikap.bas';
	public $debug_hex='./machikap/QRCODE10.hex';
	
	// Functions to be exported
	public $functions=array(
		'machikania_init',
		'qrcodegen_encodeText_wrapped',
		'qrcodegen_getSize',
		'qrcodegen_getModule',
	);
};

/*
	Main class to execute everything
*/

class mainclass {
	public $config;
	private $dis_file;
	private $map_file;
	private $hex_file;
	private $min,$max;
	public $log='';
	public $code='';
	
	function __construct(){
		ob_start();
		// Get configration
		$this->config=new configclass;
		
		// Open files being used
		$this->dis_file=file_get_contents($this->config->dis_file);
		$this->map_file=file_get_contents($this->config->map_file);
		$this->hex_file=file_get_contents($this->config->hex_file);
		
		// Check the used RAM area
		$this->MinAndMax();
		
		// List up functions
		$this->functionList();
		
		// Construct the code
		$this->constructCodes();
		
		$this->log.=ob_get_contents();
		ob_end_flush();
	}
	
	function MinAndMax(){
		// Check map file
		// Example:
		// RAM              0x20000000         0x00030000         xrw
		if (!preg_match('/[\r\n]RAM\s+0x(200[0-3][0-9a-f]{4})\s+0x([0-9a-f]+)\s+xrw/',$this->map_file,$m)) exit('Unknown error at '.__LINE__);
		$this->min=hexdec($m[1]);
		$this->max=hexdec($m[1])+hexdec($m[2]);
		echo "\nRam area: 0x",dechex($this->min),' - 0x',dechex($this->max),"\n\n";
	}
	
	/*
		List up functions
		example: 2001005e <hold_non_core0_in_bootrom>:
	*/
	function functionList(){
		if (!preg_match_all("/[\r\n]([12]0[0-9a-f]{6})\s+<([^>]+)>/",$this->dis_file,$m)) exit('Unknown error at '.__LINE__);
		$functions=array();
		for($i=0;$i<count($m[0]);$i++) $functions[$m[2][$i]]=hexdec($m[1][$i])-$this->min;
		$this->functions=$functions;	
	}
	
	/*
		Code construction
	*/
	function constructCodes(){
		$addr='$'.dechex($this->min);
		$len=$this->max-$this->min;
		$fnhex=preg_replace('@.*/@','',strtoupper($this->config->hex_file));
		$code="
			useclass CLDHEX
			usevar C_CODE
			gosub INIT_C
			end

			label INIT_C
			  var A,V
			  REM Load the main code
			  A=$addr
			  C_CODE=new(CLDHEX,\"$fnhex\",A,$len)
			  REM data_cpy_table
		";
		
		// Read <data_cpy_table>: and copy the data from RAM to RAM
		if (preg_match('/<data_cpy_table>:([\s\S]*?)[0-9a-f]{8}:[\s]+0{8}/',$this->dis_file,$m)) {
			echo "<data_cpy_table> found. Copy data from RAM to RAM.\n";
			$i=0;
			foreach(preg_split('/[\r\n]+/',trim($m[1])) as $line){
				if (!preg_match('/[0-9a-f]{8}:[\s]+([0-9a-f]{8})[\s]+\.word[\s]+0x([0-9a-f]{8})/i',$line,$m)) 
					exit('Unknown error at '.__LINE__);
				if ($m[1]!=$m[2]) exit('Unknown error at '.__LINE__);
				switch(($i++)%3){
					case 0:
						$from=hexdec($m[1]);
						break;
					case 1:
						$to=hexdec($m[1]);
						break;
					default:
						$end=hexdec($m[1]);
						echo '  from:',dechex($from),' to:',dechex($to),' end:',dechex($end);
						$from-=$this->min;
						$to-=$this->min;
						$end-=$this->min;
						if ($from!=$to && $to<$end) {
							$code.='  FOR V=0 TO '.($end-$to-1).' STEP 4 : '.
										'POKE32 A+$'.dechex($to).'+V,PEEK32(A+$'.dechex($from).'+V) : '.
										"NEXT\n";  
						} else {
							echo ' (negligible)';							
						}
						echo "\n";
						break;
				}
			}
		}
		
		// Check the functions
		echo "Exported functions:\n";
		$code.="  REM Link functions\n";
		$code2='';
		for($i=0;$i<count($this->config->functions);$i++){
			$f=$this->config->functions[$i];
			if (!isset($this->functions[$f])) exit("Function $f not found");
			echo "  $f (at ".$this->functions[$f].")\n";
			$c_f='C_'.strtoupper($f);
			$code.='  V=(A+'.$this->functions[$f]."-DATAADDRESS($c_f)-12)>>1\n";
			$code.='  poke16 DATAADDRESS(C_'.strtoupper($f).')+8,$f000+(V>>11)'."\n";
			$code.='  poke16 DATAADDRESS(C_'.strtoupper($f).')+10,$f800+(V and $7ff)'."\n";
			$code2.='label C_'.strtoupper($f)."\n";
			$code2.='  exec $68f0,$6931,$6972,$69b3,$f000,$f800,$bd00'."\n";
			/*
				68f0          ldr    r0, [r6, #12]
				6931          ldr    r1, [r6, #16]
				6972          ldr    r2, [r6, #20]
				69b3          ldr    r3, [r6, #24]
				f000 f800     bl    <xxxx>
				bd00          pop    {pc}
			*/
		}
		
		// Call machikania_init if exists
		if (in_array('machikania_init',$this->config->functions)) {
			$code.="  REM Initialize C global variables\n";
			$code.="  gosub C_MACHIKANIA_INIT\n";
		}
		$code.="return\n\t\n";
		
		$code.=$code2;		
		
		$code=trim($code);
		$code=preg_split('/[\r\n]{1,2}[\t]*/',$code);
		$code=implode("\n",$code)."\n";
		$this->code.=$code;
	}
};

// Start
$o=new mainclass;
file_put_contents('./log.txt',$o->log);
file_put_contents('./result.txt',$o->code);
if (isset($o->config->debug_file) && file_exists($o->config->debug_file)) {
	$result=file_get_contents($o->config->debug_file);
	$result=substr($result,0,strpos($result,'label INIT_C'));
	$result.=substr($o->code,strpos($o->code,'label INIT_C'));
	file_put_contents($o->config->debug_file,$result);
}
if (isset($o->config->debug_hex)) {
	file_put_contents($o->config->debug_hex,file_get_contents($o->config->hex_file));
}
