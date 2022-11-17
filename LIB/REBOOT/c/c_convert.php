<?php

/*
	This program is provided under the LGPL license ver 2.1
	c_convert.php ver 0.1, written by Katsumi.
	https://github.com/kmorimatsu
*/

/*
	Configuration
*/

class configclass{
	// File names
	public $dis_file='./build/blink.dis';
	public $map_file='./build/blink.elf.map';
	public $hex_file='./build/blink.hex';
	public $debug_file='./machikap/machikap.bas';
	
	// Functions to be exported
	public $functions=array(
//		'machikania_init',
		'reboot',
	);
	
	// Additional .rodata to be used (function names are excluded)
	public $rodata=array(
	);
	
	// Excluded addresses as .rodata and RAM
	public $excluded=array(
		0x20040000,
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
	private $bin;
	private $rodata=array();
	private $funcsneeded=array();
	private $funccode=array();
	private $bllist=array();
	private $rodatavectors=array();
	private $rodatacode=array();
	private $ramfuncvectors=array();
	private $ramvectors=array();
	private $callbackvectors=array();
	private $functions,$donefunctions;
	private $start=0xffffffff;
	private $end=0;
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
		
		// Read HEX to construct binary data
		$this->readHex();
		$this->copyFlashToRam();
		
		// Check .rodata
		foreach($this->config->rodata as $func) $this->checkRodata($func);
		
		$this->log.=ob_get_contents();
		ob_end_flush();
		
		// Check all functions
		$this->donefunctions=array();
		$this->functions=$this->config->functions;
		while($func=array_shift($this->functions)) {
			ob_start();
			$this->checkFunc($func);
			$this->log.=ob_get_contents();
			ob_end_flush();
		}
		
		/*
		ob_start();
		echo '$this->rodata ';
		print_r($this->rodata);
		echo '$this->rodatavectors ';
		print_r($this->rodatavectors);
		echo '$this->ramvectors ';
		print_r($this->ramvectors);
		echo '$this->ramfuncvectors ';
		print_r($this->ramfuncvectors);
		echo '$this->funcsneeded ';
		print_r($this->funcsneeded);
		echo '$this->bllist ';
		print_r($this->bllist);
		$this->log.=ob_get_contents();
		ob_end_flush();
		//*/
		
		ob_start();
		$this->linkBL();
		$this->addCodes();
		$this->log.=ob_get_contents();
		ob_end_flush();
	}
	
	/*
	 Intel HEX format example
	 :040bf000ffffffcf35
	    +--------------------- Byte count
	    |    +---------------- Address
	    |    |  +------------- Record type (00:Data, 01:EOF, 04: Extended linear addres, 05: Start Linear Address)
	    |    |  |        +---- Data
	    |    |  |        |  +- Checksum
	    |    |  |        |  |
	 : 04 0bf0 00 ffffffcf 35
	*/
	function readHex(){
		// $m[1]: Byte count, $m[2]: Address, $m[3]: Record type, $m[4]: Data, $m[5]: Checksum 
		if (!preg_match_all('/:([0-9a-f]{2})([0-9a-f]{4})([0-9a-f]{2})([0-9a-f]*)([0-9a-f]{2})[\r\n]/',
			strtolower($this->hex_file),$m)) exit('HEX file error');
		$addrh=0;
		$this->bin=array();
		for($i=0;$i<count($m[0]);$i++){
			switch($m[3][$i]){
				case '00':
					$addr=hexdec($m[2][$i]) | $addrh;
					for($j=0;$j<hexdec($m[1][$i]);$j++) $this->bin[$addr+$j]=hexdec(substr($m[4][$i],$j<<1,2));
					break;
				case '01':
					$i=count($m[0]);
					break;
				case '04':
					$addrh=hexdec(substr($m[4][$i],0,hexdec($m[1][$i])<<1))<<16;
					break;
				case '05':
					break;
				default:
					exit('HEX file error');
			}
		}
	}
	function copyFlashToRam(){
		// Read <data_cpy_table>: and copy data from flash to RAM
		if (!preg_match('/<data_cpy_table>:([\s\S]*?)[0-9a-f]{8}:[\s]+0{8}/',$this->dis_file,$m)) return;
		echo "<data_cpy_table> found. Copy data from flash to RAM.\n";
		$i=0;
		foreach(preg_split('/[\r\n]+/',trim($m[1])) as $line){
			echo "$line\n";
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
					while($to<$end){
						$this->bin[$to++]=$this->bin[$from++];
						$this->bin[$to++]=$this->bin[$from++];
						$this->bin[$to++]=$this->bin[$from++];
						$this->bin[$to++]=$this->bin[$from++];
					}
					break;
			}
		}
	}
	
	/*
		checkRodata() checks if the function has .rodata in *.map file. If found, update $rodata
		checkIfRodata() checks $rodata if the specified address is within rodata
	*/
	function checkRodata($func){
		if (!preg_match('/[\r\n][\s]*\.rodata\.'.$func.'\..*[\r\n]{2,4}'.
			'[\s]*0x(10[0-9a-f]{6})[\s]+(0x[0-9a-f]+)[\s]/',$this->map_file,$m)) return 0;
		$start=hexdec($m[1]);
		$len=hexdec($m[2]);
		echo ".rodata.$func at: 0x",dechex($start),", length: 0x",dechex($len),"\n";
		$this->rodata[]=array(
				'start'=>$start,
				'length'=>$len
			);
	}
	function checkIfRodata($addr){
		if (in_array($addr,$this->config->excluded)) return 0;
		for($i=0;$i<count($this->rodata);$i++){
			$start=$this->rodata[$i]['start'];
			$length=$this->rodata[$i]['length'];
			if ($start<=$addr && $addr<$start+$length) {
				// .rodata found
				if (!isset($this->rodata[$i]['codestart'])) {
					$this->rodata[$i]['codestart']=2*count($this->rodatacode);
					for($j=0;$j<$length;$j+=4){
						$this->rodatacode[]=$this->bin[$start+$j+0] | ($this->bin[$start+$j+1]<<8);
						$this->rodatacode[]=$this->bin[$start+$j+2] | ($this->bin[$start+$j+3]<<8);
					}
				}
				return 1;
			}
		}
		return 0;
	}
	
	function checkIfCallback($addr){
		if (!($addr&1)) return 0;
		$addr-=1;
		if (!preg_match('/[\r\n]'.dechex($addr).' <([^>]+)>:[\r\n]/',$this->dis_file,$m)) return 0;
		return $m[1];
	}
	
	private $ramdata;
	function checkIfRAM($addr){
		if ($addr<0x20000000 || 0x20040000<=$addr) return 0;
		if (in_array($addr,$this->config->excluded)) return 0;
		if (!$this->ramdata){
			if (!preg_match_all('/0x(200[0-3][0-9a-f]{4})[\s]+0x([0-9a-f]+)/',$this->map_file,$m)) exit('Unknown error at '.__LINE__);
			$this->ramdata=array();
			for($i=0;$i<count($m[0]);$i++) $this->ramdata[hexdec($m[1][$i])]=hexdec($m[2][$i]);
		}
		foreach($this->ramdata as $ramaddr=>$len){
			if ($ramaddr<=$addr && $addr<$ramaddr+$len) return $len;
		}
		return 0;
	}
	function checkIfRAMcode($addr){
		$addr&=0xfffffffe;
		if (preg_match('/[\r\n]'.dechex($addr).'[\s]+<([^>]+)>:[\r\n]/',$this->dis_file,$m)) return $m[1];
		else return 0;
	}

	function checkFunc($func){
		$this->donefunctions[]=$func;
		echo "----------\n";
		// Get disassembly
		if (!preg_match("/[\r\n]([12]0[0-9a-f]{6})\s+<$func>:([\s\S]*?)(\r\r|\n\n|\r\n\r\n)/",$this->dis_file,$m)) 
			exit("$func not found");
		$addr=hexdec($m[1]);
		if (!preg_match_all('/[0-9a-f]{8}:.*/',trim($m[2]),$m)) exit('Unknown error at '.__LINE__);
		$dis='';
		for($i=0;$i<count($m[0]);$i++) $dis.=$m[0][$i]."\n";
		if (!preg_match('/(^|[\r\n])([0-9a-f]{8}).*$/',$dis,$m)) exit($dis.'Unknown error at '.__LINE__);
		$end=hexdec($m[2])+4;
		echo "function name: $func (",dechex($addr),'-',dechex($end-1),")\n";
		$this->funcsneeded[$func]=array(
				'address'=>$addr,
				'length'=>$end-$addr,
				'codestart'=>2*count($this->funccode)
			);
		// Create function code
		echo 'C_FUNCTIONS+',2*count($this->funccode),"\n";
		$funccode_start=2*count($this->funccode);
		for($i=$addr;$i<$end;$i+=4){
			$this->funccode[]=$this->bin[$i+0] | ($this->bin[$i+1]<<8);
			$this->funccode[]=$this->bin[$i+2] | ($this->bin[$i+3]<<8);
		}
		// Check .rodata
		$this->checkRodata($func);
		// Check .word in flash and RAM area
		if (preg_match_all('/(10[0-9a-f]{6}):[\s]+([0-9a-f]{8})[\s]+\.word[\s]+0x([0-9a-f]{8})/',$dis,$m)) {
			for($i=0;$i<count($m[0]);$i++){
				if ($m[2][$i]!=$m[3][$i]) continue;
				$val=hexdec($m[2][$i]);
				if ($cb=$this->checkIfCallback($val)) {
					echo "at: ",$m[1][$i],", callback: ",$cb;
					$this->callbackvectors[hexdec($m[1][$i])-$addr+$funccode_start]=$cb;
					if (!in_array($cb,$this->functions) && !in_array($cb,$this->donefunctions)) {
						echo ' (additional function)';
						$this->functions[]=$cb;
					}
					echo "\n";
				} else if ($this->checkIfRodata($val)) {
					echo "at: ",$m[1][$i],", .rodata: 0x",$m[2][$i],"\n";
					$this->rodatavectors[hexdec($m[1][$i])-$addr+$funccode_start]=$val;
				} else if (substr($m[2][$i],0,3)=='200') {
					if (isset($this->bin[$val])) {
						echo 'Using RAM function area: 0x'.dechex($val)."\n";
					}
					if ($this->checkIfRAM($val)) {
						$t=$this->checkIfRAMcode($val);
						if ($t) {
							// This is a RAM code
							if (!in_array($t,$this->functions) && !in_array($t,$this->donefunctions)) {
								echo "at: ",$m[1][$i],", calling another RAM function: ",$t,"\n";
								$this->functions[]=$t;
							} else {
								echo "at: ",$m[1][$i],", calling RAM function: ",$t,"\n";
							}
							$this->ramfuncvectors[hexdec($m[1][$i])-$addr+$funccode_start]=array(
									'func'=>$t,
									'16bit'=>$val & 1
								);
						} else {
							echo "at: ",$m[1][$i],", RAM: 0x",$m[2][$i],"\n";
							$this->ramvectors[hexdec($m[1][$i])-$addr+$funccode_start]=$val;
						}
					} elseif (!in_array($val,$this->config->excluded)) {
						echo "at: ",$m[1][$i],", Unknown RAM: 0x",$m[2][$i],"\n";
						exit;
					}
				}
			}
		}
		// Check functions called. Following line is an example
		// 10001c4c:	f7ff fe4e 	bl	100018ec <reg>
		if (preg_match_all('/(10[0-9a-f]{6}):[\s]+f[0-9a-f]{3}[\s]+f[0-9a-f]{3}[\s]+bl[\s]+10[0-9a-f]{6}[\s]+<([^>+]+)>/',$dis,$m)) {
			for($i=0;$i<count($m[0]);$i++){
				// Update bllist
				echo "at: ",$m[1][$i],", calling function: ",$m[2][$i];
				$this->bllist[hexdec($m[1][$i])-$addr+$funccode_start]=$m[2][$i];
				if (!in_array($m[2][$i],$this->functions) && !in_array($m[2][$i],$this->donefunctions)) {
					echo ' (additional function)';
					$this->functions[]=$m[2][$i];
				}
				echo "\n";
			}
		}

		echo "----------\n\n";
	}
	
	function linkBL(){
		echo "List of BL instructions\n";
		foreach($this->bllist as $pos=>$func){
			$from=$pos+4;
			$to=$this->funcsneeded[$func]['codestart'];
			$d=($to-$from)/2;
			$bl2=0xf800 | ($d&0x7ff);
			$d>>=11;
			$bl1=0xf000 | ($d&0x7ff);
			$this->funccode[$pos/2]=$bl1;
			$this->funccode[$pos/2+1]=$bl2;
			echo '$',dechex($bl1),',$',dechex($bl2),': at C_FUNCTIONS+',$pos,' to C_FUNCTIONS+',$to,"\n";
		}
	}
	
	private $ramareastruct=array();
	function addCodes(){
		// Calculate length of required RAM area
		$clamlen=0;
		foreach($this->ramvectors as $vector=>$addr) {
			if (!isset($this->ramareastruct[$addr])) {
				$this->ramareastruct[$addr]=$clamlen;
				$length=$this->checkIfRAM($addr);
				$length=(int)($length/4+3);
				$clamlen+=$length;
			}
		}
		// Create the code
		$code="
			USEVAR C_RAM
			GOSUB INIT_C
			END

			LABEL INIT_C
			  DIM C_RAM($clamlen)
		";
		
		// Add ram vectors
		$code.="  REM ram vectors\n";
		foreach($this->ramvectors as $vector=>$addr) {
			$code.="  POKE32 DATAADDRESS(C_FUNCTIONS)+$vector,C_RAM+".(4*$this->ramareastruct[$addr])."\n";
		}
		// Add rodata vectors
		$code.="  REM rodata vectors\n";
		foreach($this->rodatavectors as $vector=>$addr) {
			$pos=-1;
			for($i=0;$i<count($this->rodata);$i++){
				$start=$this->rodata[$i]['start'];
				$length=$this->rodata[$i]['length'];
				if ($start<=$addr && $addr<$start+$length) {
					$pos=$this->rodata[$i]['codestart']+$addr-$start;
					break;
				}
			}
			if ($pos<0) exit('Unknown error at '.__LINE__);
			$code.="  POKE32 DATAADDRESS(C_FUNCTIONS)+$vector,DATAADDRESS(C_RODATA)+".($pos)."\n";
		}
		// Add ram function vectors
		$code.="  REM ram function vectors\n";
		foreach($this->ramfuncvectors as $vector=>$func) {
			$code.="  POKE32 DATAADDRESS(C_FUNCTIONS)+$vector,DATAADDRESS(C_FUNCTIONS)+".
				($this->funcsneeded[$func['func']]['codestart']+$func['16bit'])."\n";
		}
		// Add callback function vectors
		$code.="  REM callback function vectors\n";
		foreach($this->callbackvectors as $vector=>$func) {
			$code.="  POKE32 DATAADDRESS(C_FUNCTIONS)+$vector,DATAADDRESS(C_FUNCTIONS)+".
				($this->funcsneeded[$func]['codestart']+1)."\n";
		}		
		// Call machikania_init if exists
		if (isset($this->funcsneeded['machikania_init'])) {
			$code.="  REM Initialize C global variables\n";
			$code.="  GOSUB C_MACHIKANIA_INIT\n";
		}
		$code.="\nRETURN\n\t\n";
		
		// Add C-calling subroutines
		$code.="ALIGN4\n";
		$funccount=count($this->config->functions);
		for($i=0;$i<$funccount;$i++){
			$code.='LABEL C_'.strtoupper($this->config->functions[$i])."\n";
			$origin=12+$i*16;
			$destination=$funccount*16+$this->funcsneeded[$this->config->functions[$i]]['codestart'];
			$d=($destination-$origin)/2;
			$bl2=0xf800 | ($d&0x7ff);
			$d>>=11;
			$bl1=0xf000 | ($d&0x7ff);
			$code.='  EXEC $68f0,$6931,$6972,$69b3,$'.dechex($bl1).',$'.dechex($bl2).',$bd00,$46c0'."\n";
			/*
				68f0          ldr    r0, [r6, #12]
				6931          ldr    r1, [r6, #16]
				6972          ldr    r2, [r6, #20]
				69b3          ldr    r3, [r6, #24]
				f000 f800     bl    <xxxx>
				bd00          pop    {pc}
				46c0          nop
			*/
		}
		$code.="\n\t\n";
		
		// Add c codes
		$code.="REM ".(2*count($this->funccode))." bytes\n";
		$code.="LABEL C_FUNCTIONS\n";
		$code.=$this->addCodeSub($this->funccode);
		$code.="\n\t\n";
		
		// Add rodata
		$code.="REM ".(2*count($this->rodatacode))." bytes\n";
		$code.="LABEL C_RODATA\n";
		$code.=$this->addCodeSub($this->rodatacode);
		$code.="\n\t\n";
		
		$code=trim($code);
		$code=preg_split('/[\r\n]{1,2}[\t]*/',$code);
		$code=implode("\n",$code)."\n";
		// Add function code
		
		$this->code.=$code;
	}
	function addCodeSub($flashcode){
		if (!count($flashcode)) return;
		$code='EXEC ';
		for($i=0;$i<count($flashcode);$i++){
			$code.='$';
			if ($flashcode[$i]<0x10) $code.='000';
			elseif ($flashcode[$i]<0x100) $code.='00';
			elseif ($flashcode[$i]<0x1000) $code.='0';
			$code.=dechex($flashcode[$i]);
			if ($i<count($flashcode)-1) {
				if (($i&15)==15) $code.=",\n     ";
				else $code.=',';
			}
		}
		return $code;
	}
	
};

// Start
$o=new mainclass;
file_put_contents('./log.txt',$o->log);
file_put_contents('./result.txt',$o->code);
if (isset($o->config->debug_file) && file_exists($o->config->debug_file)) {
	$result=file_get_contents($o->config->debug_file);
	$result=substr($result,0,strpos($result,'LABEL INIT_C'));
	$result.=substr($o->code,strpos($o->code,'LABEL INIT_C'));
	file_put_contents($o->config->debug_file,$result);
}

/*
	TODO:
	1. Explore *.dis for function (from address: done, length: done, stored in $this->funcsneeded)
		Check BL assembly for imorted functions (done)
		Check .word for imported flash region (from address: done, length: done, stored in $this->rodata)
		Check .word for imported RAM region (from address: done, length: $this->checkIfRAM())
		Check .word for callback function (done, stored in $this->callbackvectors)
		List BL assembly address for modifying later (done, stored in $this->bllist)
		List .word for .rodata flash area (done, stored in $this->rodatavectors)
		List .word for RAM area (done, $this->ramvectors)
		List .word for RAM function (done, $this->ramfuncvectors)
	2. Explore *.hex and create binary code (done)
	3. Read <data_cpy_table> and copy corresponding flash area to binary RAM code (done)
	4. Create function code (done, stored in $this->funccode)
	5. Create flush rodata code (done, stored in $this->rodatacode)
	6. Create RAM area (by "USEVER C_RAM" and "DIM C_RAM(xxx), done, stored in $this->ramareastruct)
	7. Link BL assembly (done)
	8. Link RAM function vectors (done)
	9. Link RAM vectors (done)
	10. Preserve RAM area defined in <data_cpy_table> (???)
*/
