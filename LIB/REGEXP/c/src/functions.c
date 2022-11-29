/*
   This program is provided under the LGPL license ver 2.1
   Written by Katsumi.
   https://github.com/kmorimatsu
*/

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "regexp.h"
#include "pico/stdlib.h"
#include "machikania.h"
#include "functions.h"

// Local prototypes
char* get_curly_nums(char* str, int* min, int* max);
char* support_curly_sub(char* str,char endc, char** res);

char* case_insensitive(char* str){
	int len=strlen(str);
	int max=len*4+5;
	char* ret=calloc(max,1);
	char* res=ret;
	char c,c2;
	if (!ret) regerror("malloc failed");
	int i=0;
	while(res<ret+max && (c=(str++)[0])){
		switch(c){
			case '\\':
				(res++)[0]=c;
				(res++)[0]=(str++)[0];
				break;
			case '[':
				// For example:
				//	[abc] => [aAbBcC]
				//	[a-c] => [a-cA-C]
				//	[A-C] => [A-Ca-c]
				(res++)[0]=c;
				while(res<ret+max && (c=(str++)[0])){
					if ('A'<=c && c<='Z') {
						(res++)[0]=c;
						if ('-'==str[0]) {
							str++;
							(res++)[0]='-';
							c2=(str++)[0];
							(res++)[0]=c2;
							(res++)[0]=c+0x20;
							(res++)[0]='-';
							(res++)[0]=c2+0x20;
						} else {
							(res++)[0]=c+0x20;
						}
					} else if ('a'<=c && c<='z') {
						(res++)[0]=c;
						if ('-'==str[0]) {
							str++;
							(res++)[0]='-';
							c2=(str++)[0];
							(res++)[0]=c2;
							(res++)[0]=c-0x20;
							(res++)[0]='-';
							(res++)[0]=c2-0x20;
						} else {
							(res++)[0]=c-0x20;
						}
					} else if ('-'==c || '\\'==c) {
						(res++)[0]=c;
						(res++)[0]=(str++)[0];
					} else if (']'==c) {
						(res++)[0]=c;
						break;
					} else {
						(res++)[0]=c;
					}
				
				}
				break;
			default:
				if ('A'<=c && c<='Z') {
					(res++)[0]='[';
					(res++)[0]=c+0x20;
					(res++)[0]=c;
					(res++)[0]=']';
				} else if ('a'<=c && c<='z') {
					(res++)[0]='[';
					(res++)[0]=c;
					(res++)[0]=c-0x20;
					(res++)[0]=']';
				} else {
					(res++)[0]=c;
				}
				break;
		}
	}
	return ret;
}

char* support_curly(char* str){
	int len=strlen(str);
	char* str2=str;
	volatile int max=1; // Don'y know why "volatile" is required for the line, "if (max<b) max=b;".
	int i,a,b;
	int cnum=0;
	// Get the max number
	while(1){
		switch((str++)[0]){
			case 0:
				break;
			case '\\':
				str++;
				continue;
			case '{':
				cnum++;
				str=get_curly_nums(str,&a,&b);
				if (max<b) max=b;
				continue;
			default:
				continue;
		}
		break;
	}
	// Allocate memory
	// Longest case is like "[a-z]{2,4}" => "(?:[a-z][a-z]|[a-z][a-z][a-z]|[a-z][a-z][a-z][a-z])"
	// Therefore, allocate memory with bytes of "(len+1)*max+cnum*3+1"
	// , where "(len+1)" is for '|' or ')' and "cnum*3" is for "(?:"
	char* ret=calloc((len+1)*max+cnum*3+1,1);
	char* res=ret;
	// Compile
	support_curly_sub(str2,0,&res);
	return ret;
}

char* get_curly_nums(char* str, int* min, int* max){
	*min=strtol(str,&str,10);
	switch((str++)[0]){
		case '}':
			*max=*min;
			break;
		case ',':
			*max=strtol(str,&str,10);
			if ('}'!=(str++)[0]) *max=*min-1;
			break;
		default:
			*max=*min-1;
			break;
	}
	if (*max<*min) regerror("{ } error");
	return str;
}

char* support_curly_sub(char* str,char endc, char** pres){
	char* res=(char*)(*pres);
	char* begin=str;
	char* end=str;
	char c;
	int min,max,i,j;
	while(c=(res++)[0]=(str++)[0]){
		if (c==endc) break;
		if ('{'!=c) begin=str-1;
		switch(c){
			case '\\':
				(res++)[0]=(str++)[0];
				continue;
			case '(':
				str=support_curly_sub(str,')',&res);
				continue;
			case '[':
				str=support_curly_sub(str,']',&res);
				continue;
			case '{':
				res--;
				end=str-1;
				str=get_curly_nums(str,&min,&max);
				if (min==max) {
					// {num} expression
					while(0<(--min)){
						for(i=0;begin+i<end;i++) (res++)[0]=begin[i];
					}
				} else {
					// {min,max} expression
					res-=end-begin;
					(res++)[0]='(';
					(res++)[0]='?';
					(res++)[0]=':';
					while(min<=max){
						for(j=0;j<max;j++){
							for(i=0;begin+i<end;i++) (res++)[0]=begin[i];
						}
						if (min<max) (res++)[0]='|';
						else (res++)[0]=')';
						max--;
					}
				}
				continue;
			default:
				continue;
		}
	}
	*pres=res;
	return str;
}

char* support_non_s(char* str){
	int len=strlen(str);
	// "." => "[^\r\n]" conversion
	char* ret=calloc(len*5+1,1);
	char* res=ret;
	while(1){
		switch((res++)[0]=(str++)[0]){
			case '\\':
				(res++)[0]=(str++)[0];
				continue;
			case '.':
				res--;
				(res++)[0]='[';
				(res++)[0]='^';
				(res++)[0]='\r';
				(res++)[0]='\n';
				(res++)[0]=']';
				continue;
			case 0:
				break;
			default:
				continue;
		}
		break;
	}
	return ret;
}

volatile int g_options;
void set_options(char* str){
	int op=0;
	while(1){
		switch((str++)[0]){
			case 'i':
				op|=OPTION_LI;
				continue;
			case 's':
				op|=OPTION_LS;
				continue;
			case 'm':
				op|=OPTION_LM;
				continue;
			case 0:
				break;
			default:
				continue;
		}
		break;
	}
	g_options=op;
}

int get_option(int option){
	return (g_options & option) ? 1:0;
}

char* g_exptest;
char* precomp(char* re, char* options){
	char* ret;
	char* re2=0;
	set_options(options);
	// Support "i" option
	if (get_option(OPTION_LI)) re=re2=case_insensitive(re);
	// Support "s" option
	if (!get_option(OPTION_LS)) {
		re=support_non_s(re);
		if (re2) free(re2);
		re2=re;
	}
	// Support "{ }"
	ret=support_curly(re);
	if (re2) free(re2);
	free(re);
	g_exptest=ret;
	return ret;
}
