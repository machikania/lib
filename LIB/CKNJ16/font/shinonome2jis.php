<?php

/*

	Binary font file generator for Shinonome 16x16 font.
	Place 'shnmk16.bdf' in the same directory and run this script.
	Place 'shnm8x16.bdf' in the same directory and run this script.
	The font file is used for EUC-JP.
	On 2/23/2019, Shinonome font is available from: https://www.mgo-tec.com/kanji-font-shinonome

*/

$tfile=file_get_contents('./shnm8x16.bdf');
$ftable=array();
preg_replace_callback('/STARTCHAR[\s]+([0-9a-f]{2})[\s\S]*?(([0-9a-f]{2}[\s]+){16})/',function($m) use(&$ftable){
	/* 0x23: # */
	/* example:
		STARTCHAR 23
		ENCODING 35
		SWIDTH 480 0
		DWIDTH 8 0
		BBX 8 16 0 -2
		BITMAP
		00
		12
		12
		12
		7f
		24
		24
		24
		24
		24
		fe
		48
		48
		48
		48
		00
		ENDCHAR
	*/
	$ftable[hexdec($m[1])]=preg_replace('/[\s]+/','',$m[2]);
},$tfile);
$ftable[0x7f]='00000000000000000000000000000000';
//print_r($ftable);exit;

$result='';
for($code=0x20;$code<=0x7f;$code++){
	for($i=0;$i<32;$i+=2){
		$result.=chr(hexdec(substr($ftable[$code],$i,2)));
	}
}
// half font area is 1536 bytes (16*96)
//file_put_contents('./result',$result);exit;

$tfile=file_get_contents('./shnmk16.bdf');
$ftable=array();
preg_replace_callback('/STARTCHAR[\s]+([0-9a-f]{4})[\s\S]*?(([0-9a-f]{4}[\s]+){16})/',function($m) use(&$ftable){
	/* JIS 0x3835: Œ³ */
	/* example:
		STARTCHAR 3835
		ENCODING 14389
		SWIDTH 960 0
		DWIDTH 16 0
		BBX 16 16 0 -2
		BITMAP
		0000
		0ff8
		0000
		0000
		0000
		0000
		7fff
		0220
		0220
		0220
		0220
		0420
		0420
		0821
		1011
		200f
		ENDCHAR
	*/
	$ftable[hexdec($m[1])]=preg_replace('/[\s]+/','',$m[2]);
},$tfile);
//print_r($ftable);exit;

for($code=0x2121;$code<=0x7426;$code++){
	if (isset($ftable[$code])) {
		for($i=0;$i<64;$i+=2){
			$b=substr($ftable[$code],$i,2);
			$result.=chr(hexdec($b));
		}
	} else {
		$result.="\x00\x00\x00\x00\x00\x00\x00\x00";
		$result.="\x00\x00\x00\x00\x00\x00\x00\x00";
		$result.="\x00\x00\x00\x00\x00\x00\x00\x00";
		$result.="\x00\x00\x00\x00\x00\x00\x00\x00";
	}
}

file_put_contents('./SINONOME.JIS',$result);
