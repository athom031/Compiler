%{

#include <iostream>
#include <cstdlib>
#include "model.hpp"

extern int yylex();
extern ASTNode* root;
void yyerror(const char* s);
%}

%union {
	int int_val;
    char* str_val;
    Statement* stat;
    StatementList* stat_list;
    Expr* expr;
}

%type<stat_list> block statement_list
%type<expr> exp
%type<stat> statement

%token<int_val> T_NUMBER
%token<str_val> T_ID
%token T_IF T_ELSE T_INT
%token T_LTE T_GTE T_EQ T_NE T_OR T_AND

%right '='
%left T_OR
%left T_AND
%left T_LTE T_GTE T_EQ T_NE '<' '>'
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS 

%start block
%define parse.error verbose

%%

block: 
      '{' statement_list '}' { $$ = $2; root = $$; }
    ;

statement_list:
      statement { $$ = new StatementList(); $$->append($1); }
    | statement_list statement { $$ = $1; $1->append($2); }
    ;

statement: 
      T_INT T_ID ';' { $$ = new DefineStatement($2); free($2); }
    | T_INT T_ID '=' exp ';' { $$ = new DefineStatement($2, $4); free($2); }
    | exp ';' { $$ = new ExprStatement($1); }
    | T_IF '(' exp ')' block T_ELSE block { $$ = new IfElseStatement($3, $5, $7); }
    ;

exp: 
      exp '=' exp  { $$ = new Expr($1, "=", $3); }
    | exp '+' exp  { $$ = new Expr($1, "+", $3);}
    | exp '-' exp  { $$ = new Expr($1, "-", $3);}
    | exp '*' exp  { $$ = new Expr($1, "*", $3);}
    | exp '/' exp  { $$ = new Expr($1, "/", $3);}
    | exp '<' exp  { $$ = new Expr($1, "<", $3);}
    | exp '>' exp  { $$ = new Expr($1, ">", $3);}
    | exp T_LTE exp  { $$ = new Expr($1, "<=", $3); }
    | exp T_GTE exp  { $$ = new Expr($1, ">=", $3); }
    | exp T_NE exp  { $$ = new Expr($1, "!=", $3); }
    | exp T_EQ exp  { $$ = new Expr($1, "==", $3); }
    | '-' exp %prec UMINUS  { $$ = new Expr(new ExprNumber(0), "-", $2); }
    | T_ID { $$ = new ExprID($1); free($1); }
    | T_NUMBER { $$ = new ExprNumber($1); }
    | '(' exp ')' { $$ = $2; }
    ;

%%

ASTNode* root;
int Generator::counter_label = 0;
int Generator::counter_var = 0;

int main() {
	yyparse();
    std::string mil = root->gencode();
    std::cout << mil;
	return 0;
}

void yyerror(const char* s) {
	fprintf(stderr, "Parser error: %s\n", s);
	exit(1);
}
