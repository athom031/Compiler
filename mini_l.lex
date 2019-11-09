/* CS 512
 * Project Phase 2: Parser Generation Using bison
 * Written by Alex Thomas, November 10, 2019
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
  #include "mini_l.tab.h"
  
  int Ln = 1, Col = 0;
%}

DIGIT 		[0-9]
LETTER 		[a-zA-Z]
LETTER_UNDRSCR	[a-zA-Z_]
CHAR 		[0-9a-zA-Z_]
ALPHANUMER 	[0-9a-zA-Z]
WHITESPACE 	[\t ]
NEWLINE 	[\n]


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

"-"	     	{Col += yyleng; return SUB;}
"+"           	{Col += yyleng; return ADD;}
"*"            	{Col += yyleng; return MULT;}
"/"           	{Col += yyleng; return DIV;}
"%"            	{Col += yyleng; return MOD;}

"=="           	{Col += yyleng; return EQ;}
"<>"           	{Col += yyleng; return NEQ;}
"<"           	{Col += yyleng; return LT;} 
">"            	{Col += yyleng; return GT;}
"<="           	{Col += yyleng; return LTE;}
">="           	{Col += yyleng; return GTE;}

";"	       	{Col += yyleng; return SEMICOLON;}
":"            	{Col += yyleng; return COLON;}
","            	{Col += yyleng; return COMMA;}
"("            	{Col += yyleng; return L_PAREN;}
")"            	{Col += yyleng; return R_PAREN;}
"["            	{Col += yyleng; return L_SQUARE_BRACKET;}
"]"            	{Col += yyleng; return R_SQUARE_BRACKET;}
":="          	{Col += yyleng; return ASSIGN;}

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

"##".*{NEWLINE} {Col = 0; Ln += 1;}

{WHITESPACE}+	{Col += yyleng;}
{NEWLINE}+	{Ln += yyleng; Col = 0;}

. {
		printf("Error at line %d, column %d: unrecognized symbol \"%s\" \n", 
		Ln, Col, yytext);
		exit(1);}

%%
int yyparse();

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

  //yylex();
  yyparse();
  
  return 0;
}
