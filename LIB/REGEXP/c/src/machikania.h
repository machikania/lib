/*
   This program is provided under the LGPL license ver 2.1
   Written by Katsumi.
   https://github.com/kmorimatsu
*/

#include <stddef.h>

/*
	To get HEX file for embedding to MachiKania, enable MACHIKANIA definition.
	Also set(ENABLE_USB_UART 0) in CMakeLists.txt
	For testing by USB UART, disable MACHIKANIA and set(ENABLE_USB_UART 1). 
*/
#define MACHIKANIA

extern int* g_r5_8[4];
#define g_r5 g_r5_8[0];
#define g_r6 g_r5_8[1];
#define g_r7 g_r5_8[2];
#define g_r8 g_r5_8[3];

void machikania_init(void);
void* machikania_malloc(size_t bytes);
void* machikania_calloc(size_t nums, size_t size);
void machikania_free(void* addr);
void machikania_exit(int num);
void* machikania_memmove(void* buf1, void* buf2, size_t n);
void* machikania_memset(void *buf, int ch, size_t n);
void printstr(char* str);
void printint(int val);
void printhex(int val);
void printhex8(int val);
void printhex16(int val);
void printhex32(int val);
void blink(int num);

#ifdef MACHIKANIA

#define malloc(a) machikania_malloc(a)
#define calloc(a,b) machikania_calloc(a,b)
#define free(a) machikania_free(a)
#define exit(a) machikania_exit(a)

#endif //MACHIKANIA

#define LIB_CALC 0
#define LIB_CALC_FLOAT 1
#define LIB_HEX 2
#define LIB_ADD_STRING 3
#define LIB_STRNCMP 4
#define LIB_VAL 5
#define LIB_LEN 6
#define LIB_INT 7
#define LIB_RND 8
#define LIB_FLOAT 9
#define LIB_VAL_FLOAT 10
#define LIB_MATH 11
#define LIB_MID 12
#define LIB_CHR 13
#define LIB_DEC 14
#define LIB_FLOAT_STRING 15
#define LIB_SPRINTF 16
#define LIB_READ 17
#define LIB_CREAD 18
#define LIB_READ_STR 19
#define LIB_ASC 20
#define LIB_POST_GOSUB 21
#define LIB_DISPLAY_FUNCTION 22
#define LIB_INKEY 23
#define LIB_INPUT 24
#define LIB_TIMER 25
#define LIB_KEYS 26
#define LIB_NEW 27
#define LIB_OBJ_FIELD 28
#define LIB_OBJ_METHOD 29
#define LIB_PRE_METHOD 30
#define LIB_POST_METHOD 31

#define LIB_DEBUG 128
#define LIB_PRINT 129
#define LIB_LET_STR 130
#define LIB_END 131
#define LIB_LINE_NUM 132
#define LIB_DIM 133
#define LIB_RESTORE 134
#define LIB_VAR_PUSH 135
#define LIB_VAR_POP 136
#define LIB_DISPLAY 137
#define LIB_WAIT 138
#define LIB_SYSTEM 139
#define LIB_STR_TO_OBJECT 140
#define LIB_DELETE 141
#define LIB_FILE 142
#define LIB_FOPEN 143
#define LIB_FPRINT 144
#define LIB_INTERRUPT 145
#define LIB_PWM 146
#define LIB_ANALOG 147
#define LIB_SPI 148
#define LIB_I2C 149
#define LIB_SERIAL 150
#define LIB_GPIO 151
#define LIB_MUSIC 152
#define LIB_DELAYUS 153
#define LIB_DELAYMS 154
