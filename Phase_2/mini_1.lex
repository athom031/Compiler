
/* Include Stuff */
%{
  #include "mini_1.tab.h"
  
  int lineNum = 1, lineCol = 0;
%}

/* Define Patterns */
DIGIT [0-9]
DIGIT_UNDERSCORE [0-9_]
LETTER [a-zA-Z]
LETTER_UNDERSCORE [a-zA-Z_]
CHAR [0-9a-zA-Z_]
ALPHANUMER [0-9a-zA-Z]
WHITESPACE [\t ]
NEWLINE [\n]

/* Define Rules */
%%

"-"       return SUB; ++lineCol;
"+"       return ADD; ++lineCol;
"*"       return MULT; ++lineCol;
"/"       return DIV; ++lineCol;
"%"       return MOD; ++lineCol;

"=="      return EQ; lineCol += 2;
"<>"      return NEQ; lineCol += 2;
"<"       return LT; ++lineCol;
">"       return GT; ++lineCol;
"<="      return LTE; lineCol += 2;
">="      return GTE; lineCol += 2;

"function"     return FUNCTION; lineCol += yyleng;
"beginparams"  return BEGIN_PARAMS; lineCol += yyleng;
"endparams"    return END_PARAMS;  lineCol += yyleng;
"beginlocals"  return BEGIN_LOCALS; lineCol += yyleng;
"endlocals"    return END_LOCALS; lineCol += yyleng;
"beginbody"    return BEGIN_BODY; lineCol += yyleng;
"endbody"      return END_BODY; lineCol += yyleng;
"integer"      return INTEGER; lineCol += yyleng;
"array"        return ARRAY; lineCol += yyleng;
"of"           return OF; lineCol += yyleng;
"if"           return IF; lineCol += yyleng;
"then"         return THEN; lineCol += yyleng;
"endif"        return ENDIF; lineCol += yyleng;
"else"         return ELSE; lineCol += yyleng;
"while"        return WHILE; lineCol += yyleng;
"do"           return DO; lineCol += yyleng;
"foreach"      return FOREACH; lineCol += yyleng;
"in"           return IN; lineCol += yyleng;
"beginloop"    return BEGINLOOP; lineCol += yyleng;
"endloop"      return ENDLOOP; lineCol += yyleng;
"continue"     return CONTINUE; lineCol += yyleng;
"read"         return READ; lineCol += yyleng;
"write"        return WRITE; lineCol += yyleng;
"and"          return AND; lineCol += yyleng;
"or"           return OR; lineCol += yyleng;
"not"          return NOT; lineCol += yyleng;
"true"         return TRUE; lineCol += yyleng;
"false"        return FALSE; lineCol += yyleng;
"return"       return RETURN; lineCol += yyleng;

{LETTER}({CHAR}*{ALPHANUMER}+)? {
  yylval.ident_val = yytext;
  return IDENT;
  lineCol += yyleng;
	}

{DIGIT}+ {
  yylval.num_val = atoi(yytext);
  return NUMBER;
  lineCol += yyleng;
       }

({DIGIT}+{LETTER_UNDERSCORE}{CHAR}*)|("_"{CHAR}+) {
  printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter.\n",
	 lineNum, lineCol, yytext);
  exit(1);
		       }

{LETTER}({CHAR}*{ALPHANUMER}+)?"_" {
  printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore.\n",\
	 lineNum, lineCol, yytext);
  exit(1);
			   }

";"       return SEMICOLON; ++lineCol;
":"       return COLON; ++lineCol;
","       return COMMA; ++lineCol;
"("       return L_PAREN; ++lineCol;
")"       return R_PAREN; ++lineCol;
"["       return L_SQUARE_BRACKET; ++lineCol;
"]"       return R_SQUARE_BRACKET; ++lineCol;
":="      return ASSIGN; lineCol += 2;

"##".*{NEWLINE} lineCol = 0; ++lineNum;

{WHITESPACE}+   lineCol += yyleng;
{NEWLINE}+      lineNum += yyleng; lineCol = 0;

. {
  printf("Error at line %d, column %d: unrecognized symbol \"%s\" \n",
	   lineNum, lineCol, yytext);
  exit(1);
}

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
