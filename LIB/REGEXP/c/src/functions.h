/*
   This program is provided under the LGPL license ver 2.1
   Written by Katsumi.
   https://github.com/kmorimatsu
*/

char* case_insensitive(char* str);
char* support_curly(char* str);
void set_options(char* str);
int get_option(int option);
char* precomp(char* re, char* options);

extern volatile int g_options;
#define OPTION_LI 1
#define OPTION_LM 2
#define OPTION_LS 4

extern char* g_exptest;
