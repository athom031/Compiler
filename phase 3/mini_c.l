%option noyywrap

%{
#include <cstdio>
#include <cstring>
#include "model.hpp"
#include "mini_c.tab.h"

%}

%%

[ \r\n\t]	        ; // ignore all whitespace

"int"               {return T_INT;}
"if"                {return T_IF;}
"else"              {return T_ELSE;}
"+"		            {return '+';}
"-"		            {return '-';}
"*"		            {return '*';}
"/"		            {return '/';}
"("		            {return '(';}
")"		            {return ')';}
"{"		            {return '{';}
"}"		            {return '}';}
";"                 {return ';';}
"="                 {return '=';}
"<"		            {return '<';}
"<="                {return T_LTE;}
"!="                {return T_NE;}
"=="                {return T_EQ;}
">="                {return T_GTE;}
">"                 {return '>';}
"||"                {return T_OR;}
"&&"                {return T_AND;}

[a-zA-Z][0-9a-zA-Z]* {yylval.str_val = strndup(yytext, yyleng); return T_ID; }
[0-9]+		        {yylval.int_val = atoi(yytext); return T_NUMBER;}

.                   {printf("unrecognized token '%s'\n", yytext); exit(1);}
%%
