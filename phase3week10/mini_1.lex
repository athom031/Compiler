/* CS 152
 * Project Phase 3: Code Generation
 * Written by Alex Thomas, December 1, 2019
 */

/* flex input files consists of three sections: 
 * definitions
 * %%
 * rules
 * %%
 * user code
 */

/*DEFINITIONS*/
%{
  #include <string>
  #include "mini_1.tab.h"
  
  int Ln = 1, Col = 0;
  char* progName;
%}

DIGIT [0-9]
LETTER [a-zA-Z]
LETTER_UNDRSCR [a-zA-Z_]
CHAR [0-9a-zA-Z_]
ALPHANUMER [0-9a-zA-Z]
WHITESPACE [\t ]
NEWLINE [\n]


/*RULES*/
%%

"function"     	{Col += yyleng; return FUNCTION;}
"beginparams"  	{Col += yyleng; return BEGIN_PARAMS;}
"endparams"    	{Col += yyleng; return END_PARAMS;}  
"beginlocals"  	{Col += yyleng; return BEGIN_LOCALS;}
"endlocals"    	{Col += yyleng; return END_LOCALS;}
"beginbody"    	{Col += yyleng; return BEGIN_BODY;}
"endbody"      	{Col += yyleng; return END_BODY;}
"integer"      	{Col += yyleng; return INTEGER;}
"array"        	{Col += yyleng; return ARRAY;}
"of"           	{Col += yyleng; return OF;}
"if"           	{Col += yyleng; return IF;}
"then"         	{Col += yyleng; return THEN;}
"endif"        	{Col += yyleng; return ENDIF;}
"else"         	{Col += yyleng; return ELSE;}
"while"        	{Col += yyleng; return WHILE;}
"do"           	{Col += yyleng; return DO;}
"foreach"      	{Col += yyleng; return FOREACH;}
"in"          	{Col += yyleng; return IN;}
"beginloop"   	{Col += yyleng; return BEGINLOOP;}
"endloop"      	{Col += yyleng; return ENDLOOP;}
"continue"     	{Col += yyleng; return CONTINUE;}
"read"         	{Col += yyleng; return READ;}
"write"        	{Col += yyleng; return WRITE;}
"and"          	{Col += yyleng; return AND;}
"or"          	{Col += yyleng; return OR;}
"not"          	{Col += yyleng; return NOT;}
"true"         	{Col += yyleng; return TRUE;}
"false"        	{Col += yyleng; return FALSE;}
"return"      	{Col += yyleng; return RETURN;}

"-"	     	{Col++; return SUB;}
"+"           	{Col++; return ADD;}
"*"            	{Col++; return MULT;}
"/"           	{Col++; return DIV;}
"%"            	{Col++; return MOD;}

"=="           	{Col += 2; return EQ;}
"<>"           	{Col += 2; return NEQ;}
"<"           	{Col++; return LT;} 
">"            	{Col++; return GT;}
"<="           	{Col += 2; return LTE;}
">="           	{Col += 2; return GTE;}

";"	       	{Col++; return SEMICOLON;}
":"            	{Col++; return COLON;}
","            	{Col++; return COMMA;}
"("            	{Col++; return L_PAREN;}
")"            	{Col++; return R_PAREN;}
"["            	{Col++; return L_SQUARE_BRACKET;}
"]"            	{Col++; return R_SQUARE_BRACKET;}
":="          	{Col += 2; return ASSIGN;}

{LETTER}({CHAR}*{ALPHANUMER}+)? {
  		yylval.ident_val = yytext;
  		return IDENT;
  		Col += yyleng;}

{DIGIT}+ {
  		yylval.num_val = atoi(yytext);
  		return NUMBER;
  		Col += yyleng;}

({DIGIT}+{LETTER_UNDRSCR}{CHAR}*)|("_"{CHAR}+) {
		printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter.\n",
		Ln, Col, yytext);
  		exit(1);}


{LETTER}({CHAR}*{ALPHANUMER}+)?"_" {
  		printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore.\n",\
	 	Ln, Col, yytext);
  		exit(1);}

"##".*{NEWLINE} {Col = 0; Ln++;}

{WHITESPACE}+   {Col += yyleng;}
{NEWLINE}+      {Ln += yyleng; Col = 0;}

. {
		printf("Error at line %d, column %d: unrecognized symbol \"%s\" \n", 
		Ln, Col, yytext);
		exit(1);}

%%
int yyparse();
int yylex();

int main(int argc, char* argv[]) {
  if (argc == 2) {
    yyin = fopen(argv[1], "r");
    if (yyin == 0) {
      printf("Error opening file: %s\n", argv[1]);
      exit(1);
    }
  }
  else {
    yyin = stdin;
  }
  progName = strdup(argv[1]);
  
  //yylex();
  yyparse();
  
  return 0;
}
