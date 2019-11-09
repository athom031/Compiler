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
  
  int row = 1, column = 0;
%}

DIGIT [0-9]
DIGIT_UNDERSCORE [0-9_]
LETTER [a-zA-Z]
LETTER_UNDERSCORE [a-zA-Z_]
CHAR [0-9a-zA-Z_]
ALPHANUMER [0-9a-zA-Z]
WHITESPACE [\t ]
NEWLINE [\n]

IDENTIFIER 	{LETTER}({CHAR}*{ALPHANUMER}+)?
ERRIDENT_START	({DIGIT}+{LETTER_UNDRSCR}{CHAR}*)|("_"{CHAR}+)			
ERRIDENT_END	{LETTER}({CHAR}*{ALPHANUMER}+)?"_"

/*RULES*/
%%

"function"     	{column += yyleng; return FUNCTION;}
"beginparams"  	{column += yyleng; return BEGIN_PARAMS;}
"endparams"    	{column += yyleng; return END_PARAMS;}  
"beginlocals"  	{column += yyleng; return BEGIN_LOCALS;}
"endlocals"    	{column += yyleng; return END_LOCALS;}
"beginbody"    	{column += yyleng; return BEGIN_BODY;}
"endbody"      	{column += yyleng; return END_BODY;}
"integer"      	{column += yyleng; return INTEGER;}
"array"        	{column += yyleng; return ARRAY;}
"of"           	{column += yyleng; return OF;}
"if"           	{column += yyleng; return IF;}
"then"         	{column += yyleng; return THEN;}
"endif"        	{column += yyleng; return ENDIF;}
"else"         	{column += yyleng; return ELSE;}
"while"        	{column += yyleng; return WHILE;}
"do"           	{column += yyleng; return DO;}
"foreach"      	{column += yyleng; return FOREACH;}
"in"          	{column += yyleng; return IN;}
"beginloop"   	{column += yyleng; return BEGINLOOP;}
"endloop"      	{column += yyleng; return ENDLOOP;}
"continue"     	{column += yyleng; return CONTINUE;}
"read"         	{column += yyleng; return READ;}
"write"        	{column += yyleng; return WRITE;}
"and"          	{column += yyleng; return AND;}
"or"          	{column += yyleng; return OR;}
"not"          	{column += yyleng; return NOT;}
"true"         	{column += yyleng; return TRUE;}
"false"        	{column += yyleng; return FALSE;}
"return"      	{column += yyleng; return RETURN;}

"-"	     	{column += yyleng; return SUB;}
"+"           	{column += yyleng; return ADD;}
"*"            	{column += yyleng; return MULT;}
"/"           	{column += yyleng; return DIV;}
"%"            	{column += yyleng; return MOD;}

"=="           	{column += yyleng; return EQ;}
"<>"           	{column += yyleng; return NEQ;}
"<"           	{column += yyleng; return LT;} 
">"            	{column += yyleng; return GT;}
"<="           	{column += yyleng; return LTE;}
">="           	{column += yyleng; return GTE;}

";"	       	{column += yyleng; return SEMICOLON;}
":"            	{column += yyleng; return COLON;}
","            	{column += yyleng; return COMMA;}
"("            	{column += yyleng; return L_PAREN;}
")"            	{column += yyleng; return R_PAREN;}
"["            	{column += yyleng; return L_SQUARE_BRACKET;}
"]"            	{column += yyleng; return R_SQUARE_BRACKET;}
":="          	{column += yyleng; return ASSIGN;}

IDENTIFIER   	{column += yyleng; yylval.ident_val = yytext; return IDENT;}
ERRIDENT_START	{printf("Error at line %d, column %d; identifier \"%s\" must begin with a letter\n", row, column, yytext); exit(1);}
ERRIDENT_END	{printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore.\n", row, column, yytext); exit(1);}
{DIGIT}+	{column += yyleng; yylval.num_val = atoi(yytext); return NUMBER;}

"##".*{NEWLINE} {column = 0; row += 1;}

{WHITESPACE}+	{column += yyleng;}
{NEWLINE}+	{column = 0; row += yyleng;}

.		{printf("Error at line %d, column %d: unrecognized symbol \"%s\" \n", row, column, yytext); exit(1);}

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
