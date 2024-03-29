/*
Copyright (c) 1986, 1993, 1995 by University of Toronto.
Written by Henry Spencer.  Not derived from licensed software.

Permission is granted to anyone to use this software for any
purpose on any computer system, and to redistribute it in any way,
subject to the following restrictions:

1. The author is not responsible for the consequences of use of
	this software, no matter how awful, even if they arise
	from defects in it.

2. The origin of this software must not be misrepresented, either
	by explicit claim or by omission.

3. Altered versions must be plainly marked as such, and must not
	be misrepresented (by explicit claim or omission) as being
	the original software.

4. This notice must not be removed or altered.

Copyright (c) 2022 by Katsumi (https://github.com/kmorimatsu/)

This code is modified to be used for MachiKania
*/

/*
 * The first byte of the regexp internal "program" is actually this magic
 * number; the start node begins in the second byte.
 */
#define	MAGIC	0234
