/**
 * Copyright (c) 2020 Raspberry Pi (Trading) Ltd.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <stdio.h>
#include "pico/stdlib.h"
#include "qrcodegen.h"
#include "machikania.h"

bool qrcodegen_encodeText_wrapped(const char *text, uint8_t tempBuffer[], uint8_t qrcode[], enum qrcodegen_Ecc ecl) {
	return qrcodegen_encodeText(text, tempBuffer, qrcode, ecl, qrcodegen_VERSION_MIN, qrcodegen_VERSION_MAX, qrcodegen_Mask_AUTO, true);
}

int main() {
	stdio_init_all();
	machikania_init();
	for (int i=5;0<i;i--) {
		printf("%d\n",i);
		sleep_ms(1000);
	}

	const char *text = "Hello, world!";                // User-supplied text
	enum qrcodegen_Ecc errCorLvl = qrcodegen_Ecc_LOW;  // Error correction level
	
	// Make and print the QR Code symbol
	uint8_t qrcode[qrcodegen_BUFFER_LEN_MAX];
	uint8_t tempBuffer[qrcodegen_BUFFER_LEN_MAX];
	bool ok = qrcodegen_encodeText_wrapped(text, tempBuffer, qrcode, errCorLvl);
	if (!ok) return 0;
	
	// Prints the given QR Code to the console.
	int size = qrcodegen_getSize(qrcode);
	for(int y=0;y<size;y++){
		for(int x=0;x<size;x++){
			if (qrcodegen_getModule(qrcode, x, y))  printf("#");
			else printf(" ");
		}
		printf("\n");
	}
	while(true) sleep_ms(1000);
	return 0;
}
