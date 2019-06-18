<?php

/*

	Binary font file generator for Misaki 8x8 font.
	Place 'misaki_gothic.bdf' in the same directory and run this script.
	The font file is used for UTF-8.
	Misaki font was downloaded from: http://www.geocities.jp/littlimi/misaki.htm
	On 2/23/2019, Misaki font is available from: http://littlelimit.net/

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

$result='';
for($code=0x2121;$code<=0x7426;$code++){
	if (isset($ftable[$code])) {
		for($i=0;$i<16;$i+=2){
			$b=substr($ftable[$code],$i,2);
			$result.=chr(hexdec($b));
		}
	} else {
		$result.="\x00\x00\x00\x00\x00\x00\x00\x00";
	}
}

file_put_contents('./MISAKI.JIS',$result);
