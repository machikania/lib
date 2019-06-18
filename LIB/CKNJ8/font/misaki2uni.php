<?php
/*

	Binary font file generator for Misaki 8x8 font.
	Place 'misaki_gothic.bdf' in the same directory and run this script.
	Place 'JIS0208.TXT' in the same directory and run this script.
	The font file is used for UTF-8.
	Misaki font was downloaded from: http://www.geocities.jp/littlimi/misaki.htm
	On 2/23/2019, Misaki font is available from: http://littlelimit.net/
	Unicode - JIS table was obtained from: http://www.unicode.org/Public/MAPPINGS/OBSOLETE/EASTASIA/JIS/JIS0208.TXT

*/

$tfile=file_get_contents('./misaki_gothic.bdf');
$ftable=array();
preg_replace_callback('/STARTCHAR[\s]+([0-9a-f]{4})[\s\S]*?(([0-9a-f]{2}[\s]+){8})/',function($m) use(&$ftable){
	/* JIS 0x3835: Œ³ */
	/* example:
		STARTCHAR 3835
		ENCODING 14389
		SWIDTH 960 0
		DWIDTH 8 0
		BBX 8 8 0 -2
		BITMAP
		7c
		00
		fe
		28
		28
		4a
		8e
		00
		ENDCHAR
	*/
	$ftable[hexdec($m[1])]=preg_replace('/[\s]+/','',$m[2]);
},$tfile);
//print_r($ftable);

$tfile=file_get_contents('./JIS0208.TXT');
$jtable=array();
preg_replace_callback('/[\r\n]0x([0-9A-F]{4})[\s]+0x([0-9A-F]{4})[\s]+0x([0-9A-F]{4})/',function($m) use(&$jtable,&$ftable){
	// $m[1]: SJIS, $m[2]: JIS, $m[3]: UTF16
	if ($ftable[hexdec($m[2])]) {
		$jtable[hexdec($m[3])]=$ftable[hexdec($m[2])];
	}
},$tfile);

$result='';
for($code=0x0000;$code<=0xffff;$code++){
	/*
		Skip:
			0500 - 1fff
			2700 - 2fff
			3100 - 4dff
			a000 - feff
		Valid:
			0000 - 04ff (0500, total 0500)
			2000 - 26ff (0700, total 0c00)
			3000 - 30ff (0100, total 0d00)
			4e00 - 9fff (5200, total 5f00)
			ff00 - ffff (0100, total 6000)
		Therefore:
			if P<0x0500 then
			  P=P-0x500
			elseif P<0x2000 then
			  REM ERR
			elseif P<0x2700 then
			  P=P-0x2000+0x0500
			elseif P<0x3000 then
			  REM ERR
			elseif P<0x3100 then
			  P=P-0x3000+0x0c00
			elseif P<0x4e00 then
			  REM ERR
			elseif P<0xa000 then
			  P=P-0x4e00+0x0d00
			elseif P<0xff00 then
			  REM ERR
			else
			  P=P-0xff00+0x5f00
			endif
	*/
	switch($code){
		case 0x0500: $code=0x2000; break;
		case 0x2700: $code=0x3000; break;
		case 0x3100: $code=0x4e00; break;
		case 0xa000: $code=0xff00; break;
		default:                   break;
	}
	if (isset($jtable[$code])) {
		for($i=0;$i<16;$i+=2){
			$b=substr($jtable[$code],$i,2);
			$result.=chr(hexdec($b));
		}
	} else {
		$result.="\x00\x00\x00\x00\x00\x00\x00\x00";
	}
}
file_put_contents('./MISAKI.UNI',$result);

