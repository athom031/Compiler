%{
#define YY_NO_UNPUT
#include <stdio.h>
#include <stdlib.h>
#include <map>
#include <string.h>
#include <vector>
void yyerror(const char* s);
int yylex();
extern int Ln;
extern int Col;
extern char* yytext;
extern char* progName;
std::string newTemp();
std::string newLabel();

char empty[1] = "";

std::map<std::string, int> variables;
// When it's a single value we want 0
// When it's an array -> map to the size of the array (# GT 0)
std::map<std::string, int> functions;
std::vector<std::string> reservedWords = {"FUNCTION", "BEGIN_PARAMS", "END_PARAMS", "BEGIN_LOCALS", "END_LOCALS", "BEGIN_BODY", "END_BODY", "INTEGER", "ARRAY", "OF", "IF", "THEN", "ENDIF", "ELSE", "WHILE", "DO", "FOREACH", "IN", "BEGINLOOP", "ENDLOOP", "CONTINUE", "READ", "WRITE", "AND", "OR", "NOT", "TRUE", "FALSE", "RETURN", "SUB", "ADD", "MULT", "DIV", "MOD", "EQ", "NEQ", "LT", "GT", "LTE", "GTE", "L_PAREN", "R_PAREN", "L_SQUARE_BRACKET", "R_SQUARE_BRACKET", "COLON", "SEMICOLON", "COMMA", "ASSIGN", "function", "Ident", "beginparams", "endparams", "beginlocals", "endlocals", "integer", "beginbody", "endbody", "beginloop", "endloop", "if", "endif", "foreach", "continue", "while", "else", "read", "do", "write"};
%}


%union{
  char* ident_val;
  int num_val;
  struct E {
    char* place;
    char* code;
    bool array;
  } expr;

  struct S {
    char* code;
  } stat;
 }

%error-verbose

%start Program

%token <ident_val> IDENT
%token <num_val> NUMBER

%type <expr> Ident LocalIdent FunctionIdent
%type <expr> Declaration_s Declaration Identifiers Var Vars
%type <stat> Statements Statement ElseStatement
%type <expr> Expression Expressions MultExp Term BoolExp RAExp RExp RExp1 Comp

%token FUNCTION
%token BEGIN_PARAMS
%token END_PARAMS
%token BEGIN_LOCALS
%token END_LOCALS
%token BEGIN_BODY
%token END_BODY

%token INTEGER
%token ARRAY
%token OF

%token IF
%token THEN
%token ENDIF
%token ELSE
%token WHILE
%token DO
%token FOREACH
%token IN
%token BEGINLOOP
%token ENDLOOP
%token CONTINUE

%token READ
%token WRITE

%token RETURN

%token TRUE
%token FALSE

%token SEMICOLON
%token COMMA
%token COLON
%token L_SQUARE_BRACKET
%token R_SQUARE_BRACKET
%token L_PAREN
%token R_PAREN

%left  ASSIGN
%left  EQ
%left  NEQ
%left  LT
%left  GT
%left  LTE
%left  GTE

%left  ADD
%left  SUB
%left  MULT
%left  DIV
%left  MOD

%left  OR
%left  AND
%right NOT

%%  /*  Grammar rules and actions follow  */

Program:         %empty
{
  std::string tempMain = "main";
  if ( functions.find(tempMain) == functions.end()) {
    char temp[128];
    snprintf(temp, 128, "Function main not declared");
    yyerror(temp);
  }
  // Check if user declared variable the same as program name
  if (variables.find(std::string(progName)) != variables.end()) {
    char temp[128];
    snprintf(temp, 128, "Declared program name as variable.");
    yyerror(temp);
  }
}
| Function Program
{
};

Function:        FUNCTION FunctionIdent SEMICOLON BEGIN_PARAMS Declarations END_PARAMS BEGIN_LOCALS Declarations END_LOCALS BEGIN_BODY Statements END_BODY
{
  std::string temp = "func ";
  temp.append($2.place);
  temp.append("\n");
  temp.append($2.code);
  temp.append($5.code);
  // Parameter initalization
  std::string init_params = $5.code;
  int param_number = 0;
  while (init_params.find(".") != std::string::npos) {
    size_t pos = init_params.find(".");
    init_params.replace(pos, 1, "=");
    std::string param = ", $";
    param.append(std::to_string(param_number++));
    param.append("\n");
    init_params.replace(init_params.find("\n", pos), 1, param);
  }
  temp.append(init_params);
  temp.append($8.code);
  std::string statements($11.code);
  // Check if there are any leftover continues (test 09)
  if (statements.find("continue") != std::string::npos) {
    printf("ERROR: Continue outside loop in function %s\n", $2.place);
  }
  temp.append(statements);
  temp.append("endfunc\n");
  
  printf("%s", temp.c_str());
};


Declaration:     Identifiers COLON INTEGER
{
  std::string vars($1.place);
  std::string temp;
  std::string variable;
  bool cont = true;

  // Build list of declarations base on list of identifiers
  // identifiers use "|" as delimeter
  size_t oldpos = 0;
  size_t pos = 0;
  bool isReserved = false;
  while (cont) {
    pos = vars.find("|", oldpos);
    if (pos == std::string::npos) {
      temp.append(". ");
      variable = vars.substr(oldpos,pos);
      temp.append(variable);
      temp.append("\n");
      cont = false;
    }
    else {
      size_t len = pos - oldpos;
      temp.append(". ");
      variable = vars.substr(oldpos, len);
      temp.append(variable);
      temp.append("\n");
    }
    //check for reserved keywords (test 05)
    for (unsigned int i = 0; i < reservedWords.size(); ++i) {
      if (reservedWords.at(i) == variable) {
        isReserved = true;
      }
    } 
    // Check for redeclaration (test 04) TODO same name as program
    if (variables.find(variable) != variables.end()) {
      char temp[128];
      snprintf(temp, 128, "Redeclaration of variable %s", variable.c_str());
      yyerror(temp);
    }
    else if (isReserved){
      char temp[128];
      snprintf(temp, 128, "Invalid declaration of reserved words %s", variable.c_str());
      yyerror(temp);
    }
    else {
      variables.insert(std::pair<std::string,int>(variable,0));
    }
    
    oldpos = pos + 1;
  }
  
  $$.code = strdup(temp.c_str());
  $$.place = strdup(empty);	      
}
| Identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER
{
  // Check if declaring arrays of size <= 0 (test 08)
  if ($5 <= 0) {
    char temp[128];
    snprintf(temp, 128, "Array size can't be less than 1");
    yyerror(temp);
  }
  
  std::string vars($1.place);
  std::string temp;
  std::string variable;
  bool cont = true;

  // Build list of declarations base on list of identifiers
  // identifiers use "|" as delimeter
  size_t oldpos = 0;
  size_t pos = 0;
  while (cont) {
    pos = vars.find("|", oldpos);
    if (pos == std::string::npos) {
      temp.append(".[] ");
      variable = vars.substr(oldpos, pos);
      temp.append(variable);
      temp.append(", ");
      temp.append(std::to_string($5));
      temp.append("\n");
      cont = false;
    }
    else {
      size_t len = pos - oldpos;
      temp.append(".[] ");
      variable = vars.substr(oldpos, len);
      temp.append(variable);
      temp.append(", ");
      temp.append(std::to_string($5));
      temp.append("\n");
    }
    // Check for redeclaraion (test 04)
    if (variables.find(variable) != variables.end()) {
      char temp[128];
      snprintf(temp, 128, "Redeclaration of variable %s", variable.c_str());
      yyerror(temp);
    }
    else {
      variables.insert(std::pair<std::string,int>(variable,$5));
    }
      
    oldpos = pos + 1;
  }
  
  $$.code = strdup(temp.c_str());
  $$.place = strdup(empty);	      
};

Declarations:    %empty
{
  $$.code = strdup(empty);
  $$.place = strdup(empty);
}
| Declaration SEMICOLON Declarations
{
  std::string temp;
  temp.append($1.code);
  temp.append($3.code);
  
  $$.code = strdup(temp.c_str());
  $$.place = strdup(empty);
};

Identifiers:     Ident
{
  $$.place = strdup($1.place);
  $$.code = strdup(empty);
}
| Ident COMMA Identifiers
{
  // use "|" as delimeter
  std::string temp;
  temp.append($1.place);
  temp.append("|");
  temp.append($3.place);
  
  $$.place = strdup(temp.c_str());
  $$.code = strdup(empty);
}

Statements:      Statement SEMICOLON Statements
{
  std::string temp;
  temp.append($1.code);
  temp.append($3.code);

  $$.code = strdup(temp.c_str());
}
| Statement SEMICOLON
{
  std::string temp;
  temp.append($1.code);

  $$.code = strdup(temp.c_str());
};

Statement:      Var ASSIGN Expression
{
  std::string temp;
  temp.append($1.code);
  temp.append($3.code);
  std::string intermediate = $3.place;
  if ($1.array && $3.array) {
    intermediate = newTemp();
    temp.append(". ");
    temp.append(intermediate);
    temp.append("\n");
    temp.append("=[] ");
    temp.append(intermediate);
    temp.append(", ");
    temp.append($3.place);
    temp.append("\n");
    temp.append("[]= ");
  }
  else if ($1.array) {
    temp.append("[]= ");
  }
  else if ($3.array) {
    temp.append("=[] ");
  }
  else {
    temp.append("= ");
  }
  temp.append($1.place);
  temp.append(", ");
  temp.append(intermediate);
  temp.append("\n");

  $$.code = strdup(temp.c_str());
}
| IF BoolExp THEN Statements ElseStatement ENDIF
{
  std::string then_begin = newLabel();
  std::string after = newLabel();
  std::string temp;

  // evaluate expression
  temp.append($2.code);
  // if true goto then label
  temp.append("?:= ");
  temp.append(then_begin);
  temp.append(", ");
  temp.append($2.place);
  temp.append("\n");
  // else code
  temp.append($5.code);
  // goto after
  temp.append(":= ");
  temp.append(after);
  temp.append("\n");
  // then label
  temp.append(": ");
  temp.append(then_begin);
  temp.append("\n");
  // then code
  temp.append($4.code);
  // after label
  temp.append(": ");
  temp.append(after);
  temp.append("\n");
  
  $$.code = strdup(temp.c_str());
}		 
| WHILE BoolExp BEGINLOOP Statements ENDLOOP
{
  std::string temp;
  std::string beginWhile = newLabel();
  std::string beginLoop = newLabel();
  std::string endLoop = newLabel();
  // replace continue
  std::string statement = $4.code;
  std::string jump;
  jump.append(":= ");
  jump.append(beginWhile);
  while (statement.find("continue") != std::string::npos) {
    statement.replace(statement.find("continue"), 8, jump);
  }
  
  temp.append(": ");
  temp.append(beginWhile);
  temp.append("\n");
  temp.append($2.code);
  temp.append("?:= ");
  temp.append(beginLoop);
  temp.append(", ");
  temp.append($2.place);
  temp.append("\n");
  temp.append(":= ");
  temp.append(endLoop);
  temp.append("\n");
  temp.append(": ");
  temp.append(beginLoop);
  temp.append("\n");
  temp.append(statement);
  temp.append(":= ");
  temp.append(beginWhile);
  temp.append("\n");
  temp.append(": ");
  temp.append(endLoop);
  temp.append("\n");

  $$.code = strdup(temp.c_str());
}
| DO BEGINLOOP Statements ENDLOOP WHILE BoolExp
{
  std::string temp;
  std::string beginLoop = newLabel();
  std::string beginWhile = newLabel();
  // replace continue
  std::string statement = $3.code;
  std::string jump;
  jump.append(":= ");
  jump.append(beginWhile);
  while (statement.find("continue") != std::string::npos) {
    statement.replace(statement.find("continue"), 8, jump);
  }
  
  temp.append(": ");
  temp.append(beginLoop);
  temp.append("\n");
  temp.append(statement);
  temp.append(": ");
  temp.append(beginWhile);
  temp.append("\n");
  temp.append($6.code);
  temp.append("?:= ");
  temp.append(beginLoop);
  temp.append(", ");
  temp.append($6.place);
  temp.append("\n");
  
  $$.code = strdup(temp.c_str());
}
| FOREACH LocalIdent IN Ident BEGINLOOP Statements ENDLOOP
{
  std::string temp;
  std::string count = newTemp();
  std::string check = newTemp();
  std::string begin = newLabel();
  std::string beginLoop = newLabel();
  std::string increment = newLabel();
  std::string endLoop = newLabel();
  // replace continue
  std::string statement = $6.code;
  std::string jump;
  jump.append(":= ");
  jump.append(increment);
  while (statement.find("continue") != std::string::npos) {
    statement.replace(statement.find("continue"), 8, jump);
  }
  // Checks for second ident
  if (variables.find(std::string($4.place)) == variables.end()) {
    char temp[128];
    snprintf(temp, 128, "Use of undeclared variable %s", $4.place);
    yyerror(temp);
  }
  // Check if second ident is scalar
  else if (variables.find(std::string($4.place))->second == 0) {
    char temp[128];
    snprintf(temp, 128, "Use of scalar variable %s in foreach", $4.place);
    yyerror(temp);
  }
  // checks for LocalIdent happen in LocalIdent (redeclaration test)

  // Initalize first ident and check
  temp.append(". ");
  temp.append($2.place);
  temp.append("\n");
  temp.append(". ");
  temp.append(check);
  temp.append("\n");
  temp.append(". ");
  temp.append(count);
  temp.append("\n");
  temp.append("= ");
  temp.append(count);
  temp.append(", 0");
  temp.append("\n");
  // Check if count is less than size of array
  temp.append(": ");
  temp.append(begin);
  temp.append("\n");
  temp.append("< ");
  temp.append(check);
  temp.append(", ");
  temp.append(count);
  temp.append(", ");
  temp.append(std::to_string(variables.find(std::string($4.place))->second));
  temp.append("\n");
  // Jump to begin loop if check is true
  temp.append("?:= ");
  temp.append(beginLoop);
  temp.append(", ");
  temp.append(check);
  temp.append("\n");
  // Jump to end loop if check is false
  temp.append(":= ");
  temp.append(endLoop);
  temp.append("\n");
  // Begin loop
  temp.append(": ");
  temp.append(beginLoop);
  temp.append("\n");
  // Set first ident to value of second ident
  temp.append("=[] ");
  temp.append($2.place);
  temp.append(", ");
  temp.append($4.place);
  temp.append(", ");
  temp.append(count);
  temp.append("\n");
  // Execute code
  temp.append(statement);
  // Increment
  temp.append(": ");
  temp.append(increment);
  temp.append("\n");
  temp.append("+ ");
  temp.append(count);
  temp.append(", ");
  temp.append(count);
  temp.append(", 1\n");
  // Jump to check
  temp.append(":= ");
  temp.append(begin);
  temp.append("\n");
  // label endLoop
  temp.append(": ");
  temp.append(endLoop);
  temp.append("\n");
  
  $$.code = strdup(temp.c_str());
}
| READ Vars
{
  std::string temp = $2.code;
  size_t pos = 0;
  do {
    pos = temp.find("|", pos);
    if (pos == std::string::npos)
      break;
    temp.replace(pos, 1, "<");
  } while (true);

  $$.code = strdup(temp.c_str());
}
| WRITE Vars
{
  std::string temp = $2.code;
  size_t pos = 0;
  do {
    pos = temp.find("|", pos);
    if (pos == std::string::npos)
      break;
    temp.replace(pos, 1, ">");
  } while (true);

  $$.code = strdup(temp.c_str());
}
| CONTINUE
{
  // insert continue on a new line
  // search for continue in loop
  // and replace with := loop check
  std::string temp = "continue\n";
  $$.code = strdup(temp.c_str());
}
| RETURN Expression
{
  std::string temp;
  temp.append($2.code);
  temp.append("ret ");
  temp.append($2.place);
  temp.append("\n");
  $$.code = strdup(temp.c_str());
};


ElseStatement:   %empty
{
  $$.code = strdup(empty);
}
| ELSE Statements
{
  $$.code = strdup($2.code);
};

Var:             Ident L_SQUARE_BRACKET Expression R_SQUARE_BRACKET
{
  // Check for use of undeclared variable (test 01)
  if (variables.find(std::string($1.place)) == variables.end()) {
    char temp[128];
    snprintf(temp, 128, "Use of undeclared variable %s", $1.place);
    yyerror(temp);
  }
  // Check for use of single value as array (test 07)
  else if (variables.find(std::string($1.place))->second == 0) {
    char temp[128];
    snprintf(temp, 128, "Indexing a non-array variable %s", $1.place);
    yyerror(temp);
  }

  std::string temp;
  temp.append($1.place);
  temp.append(", ");
  temp.append($3.place);

  $$.code = strdup($3.code);
  $$.place = strdup(temp.c_str());
  $$.array = true;
}
| Ident
{
  // Check for use of undeclared variable (test 01)
  if (variables.find(std::string($1.place)) == variables.end()) {
    char temp[128];
    snprintf(temp, 128, "Use of undeclared variable %s", $1.place);
    yyerror(temp);
  }
  // Check for use of array as single value (test 06)
  else if (variables.find(std::string($1.place))->second > 0) {
    char temp[128];
    snprintf(temp, 128, "Failed to provide index for array variable %s", $1.place);
    yyerror(temp);
  }

  $$.code = strdup(empty);
  $$.place = strdup($1.place);
  $$.array = false;
};

/* Vars is only used by read and write
 * pass back the code ".[]| dst/src"
 * replace "|" with correct < or > depending on read/write
 * in read and write production
 */
Vars:            Var
{
  std::string temp;
  temp.append($1.code);
  if ($1.array)
    temp.append(".[]| ");
  else
    temp.append(".| ");
  
  temp.append($1.place);
  temp.append("\n");

  $$.code = strdup(temp.c_str());
  $$.place = strdup(empty);
}
| Var COMMA Vars
{
  std::string temp;
  temp.append($1.code);
  if ($1.array)
    temp.append(".[]| ");
  else
    temp.append(".| ");
  
  temp.append($1.place);
  temp.append("\n");
  temp.append($3.code);
  
  $$.code = strdup(temp.c_str());
  $$.place = strdup(empty);
};

Expression:      MultExp
{
  $$.code = strdup($1.code);
  $$.place = strdup($1.place);
}
| MultExp ADD Expression
{
  $$.place = strdup(newTemp().c_str());
  
  std::string temp;
  temp.append($1.code);
  temp.append($3.code);
  temp.append(". ");
  temp.append($$.place);
  temp.append("\n");
  temp.append("+ ");
  temp.append($$.place);
  temp.append(", ");
  temp.append($1.place);
  temp.append(", ");
  temp.append($3.place);
  temp.append("\n");

  $$.code = strdup(temp.c_str());
}
| MultExp SUB Expression
{
  $$.place = strdup(newTemp().c_str());
  
  std::string temp;
  temp.append($1.code);
  temp.append($3.code);
  temp.append(". ");
  temp.append($$.place);
  temp.append("\n");
  temp.append("- ");
  temp.append($$.place);
  temp.append(", ");
  temp.append($1.place);
  temp.append(", ");
  temp.append($3.place);
  temp.append("\n");

  $$.code = strdup(temp.c_str());
};

// used only for function calls
Expressions:     %empty
{
  $$.code = strdup(empty);
  $$.place = strdup(empty);
}
| Expression COMMA Expressions
{
  std::string temp;
  temp.append($1.code);
  temp.append("param ");
  temp.append($1.place);
  temp.append("\n");
  temp.append($3.code);

  $$.code = strdup(temp.c_str());
  $$.place = strdup(empty);
}
| Expression
{
  std::string temp;
  temp.append($1.code);
  temp.append("param ");
  temp.append($1.place);
  temp.append("\n");

  $$.code = strdup(temp.c_str());
  $$.place = strdup(empty);
};


MultExp:         Term
{
  $$.code = strdup($1.code);
  $$.place = strdup($1.place);
}
| Term MULT MultExp
{
  $$.place = strdup(newTemp().c_str());
  
  std::string temp;
  temp.append(". ");
  temp.append($$.place);
  temp.append("\n");
  temp.append($1.code);
  temp.append($3.code);
  temp.append("* ");
  temp.append($$.place);
  temp.append(", ");
  temp.append($1.place);
  temp.append(", ");
  temp.append($3.place);
  temp.append("\n");

  $$.code = strdup(temp.c_str());
}
| Term DIV MultExp
{
  $$.place = strdup(newTemp().c_str());
  
  std::string temp;
  temp.append(". ");
  temp.append($$.place);
  temp.append("\n");
  temp.append($1.code);
  temp.append($3.code);
  temp.append("/ ");
  temp.append($$.place);
  temp.append(", ");
  temp.append($1.place);
  temp.append(", ");
  temp.append($3.place);
  temp.append("\n");

  $$.code = strdup(temp.c_str());
}
| Term MOD MultExp
{
  $$.place = strdup(newTemp().c_str());
  
  std::string temp;
  temp.append(". ");
  temp.append($$.place);
  temp.append("\n");
  temp.append($1.code);
  temp.append($3.code);
  temp.append("% ");
  temp.append($$.place);
  temp.append(", ");
  temp.append($1.place);
  temp.append(", ");
  temp.append($3.place);
  temp.append("\n");

  $$.code = strdup(temp.c_str());
};


Term:            Var
{
  // var can be an array or not
  if ($$.array == true) {
    std::string temp;
    std::string intermediate = newTemp();
    temp.append($1.code);
    temp.append(". ");
    temp.append(intermediate);
    temp.append("\n");
    temp.append("=[] ");
    temp.append(intermediate);
    temp.append(", ");
    temp.append($1.place);
    temp.append("\n");
    $$.code = strdup(temp.c_str());
    $$.place = strdup(intermediate.c_str());
    $$.array = false;
  }
  else {
    $$.code = strdup($1.code);
    $$.place = strdup($1.place);
  }
}
| SUB Var
{
  // Var can either be an array or not an array
  $$.place = strdup(newTemp().c_str());
  std::string temp;
  temp.append($2.code);
  temp.append(". ");
  temp.append($$.place);
  temp.append("\n");
  if ($2.array) {
    temp.append("=[] ");
    temp.append($$.place);
    temp.append(", ");
    temp.append($2.place);
    temp.append("\n");
  }
  else {
    temp.append("= ");
    temp.append($$.place);
    temp.append(", ");
    temp.append($2.place);
    temp.append("\n");
  }
  temp.append("* ");
  temp.append($$.place);
  temp.append(", ");
  temp.append($$.place);
  temp.append(", -1\n");
  
  $$.code = strdup(temp.c_str());
  $$.array = false;
}
| NUMBER
{
  $$.code = strdup(empty);
  $$.place = strdup(std::to_string($1).c_str());
}
| SUB NUMBER
{
  std::string temp;
  temp.append("-");
  temp.append(std::to_string($2));
  $$.code = strdup(empty);
  $$.place = strdup(temp.c_str());
}
| L_PAREN Expression R_PAREN
{
  $$.code = strdup($2.code);
  $$.place = strdup($2.place);
}
| SUB L_PAREN Expression R_PAREN
{
  $$.place = strdup($3.place);
  std::string temp;
  temp.append($3.code);
  temp.append("* ");
  temp.append($3.place);
  temp.append(", ");
  temp.append($3.place);
  temp.append(", -1\n");
  $$.code = strdup(temp.c_str());
}
| Ident L_PAREN Expressions R_PAREN
{
   // Check for use of undeclared function (test 2)
  if (functions.find(std::string($1.place)) == functions.end()) {
    char temp[128];
    snprintf(temp, 128, "Use of undeclared function %s", $1.place);
    yyerror(temp);
  }

  $$.place = strdup(newTemp().c_str());

  std::string temp;
  temp.append($3.code);
  temp.append(". ");
  temp.append($$.place);
  temp.append("\n");
  temp.append("call ");
  temp.append($1.place);
  temp.append(", ");
  temp.append($$.place);
  temp.append("\n");
  
  $$.code = strdup(temp.c_str());
};

BoolExp:         RAExp 
{
  $$.place = strdup($1.place);
  $$.code = strdup($1.code);
}
| RAExp OR BoolExp
{
  std::string dest = newTemp();
  std::string temp;

  temp.append($1.code);
  temp.append($3.code);
  temp.append(". ");
  temp.append(dest);
  temp.append("\n");
  
  temp.append("|| ");
  temp.append(dest);
  temp.append(", ");
  temp.append($1.place);
  temp.append(", ");
  temp.append($3.place);
  temp.append("\n");
  
  $$.code = strdup(temp.c_str());
  $$.place = strdup(dest.c_str());
};

RAExp:           RExp
{
  $$.place = strdup($1.place);
  $$.code = strdup($1.code);
}
| RExp AND RAExp
{
  std::string dest = newTemp();
  std::string temp;

  temp.append($1.code);
  temp.append($3.code);
  temp.append(". ");
  temp.append(dest);
  temp.append("\n");
  
  temp.append("&& ");
  temp.append(dest);
  temp.append(", ");
  temp.append($1.place);
  temp.append(", ");
  temp.append($3.place);
  temp.append("\n");
  
  $$.code = strdup(temp.c_str());
  $$.place = strdup(dest.c_str());
};

RExp:            NOT RExp1 
{
  std::string dest = newTemp();
  std::string temp;

  temp.append($2.code);
  temp.append(". ");
  temp.append(dest);
  temp.append("\n");
  
  temp.append("! ");
  temp.append(dest);
  temp.append(", ");
  temp.append($2.place);
  temp.append("\n");
  
  $$.code = strdup(temp.c_str());
  $$.place = strdup(dest.c_str());
}
| RExp1
{
  $$.place = strdup($1.place);
  $$.code = strdup($1.code);
};

RExp1:           Expression Comp Expression
{
  std::string dest = newTemp();
  std::string temp;  

  temp.append($1.code);
  temp.append($3.code);
  temp.append(". ");
  temp.append(dest);
  temp.append("\n");
  temp.append($2.place);
  temp.append(dest);
  temp.append(", ");
  temp.append($1.place);
  temp.append(", ");
  temp.append($3.place);
  temp.append("\n");
  
  $$.code = strdup(temp.c_str());
  $$.place = strdup(dest.c_str());
}
| TRUE
{
  char temp[2] = "1";
  $$.place = strdup(temp);
  $$.code = strdup(empty);
}
| FALSE
{
  char temp[2] = "0";
  $$.place = strdup(temp);
  $$.code = strdup(empty);
}
| L_PAREN BoolExp R_PAREN
{
  $$.place = strdup($2.place);
  $$.code = strdup($2.code);
};

Comp:            EQ
{
  std::string temp = "== ";
  $$.place = strdup(temp.c_str());
  $$.code = strdup(empty);
}
| NEQ
{
  std::string temp = "!= ";
  $$.place = strdup(temp.c_str());
  $$.code = strdup(empty);
}
| LT
{
  std::string temp = "< ";
  $$.place = strdup(temp.c_str());
  $$.code = strdup(empty);
}
| GT
{
  std::string temp = "> ";
  $$.place = strdup(temp.c_str());
  $$.code = strdup(empty);
}
| LTE
{
  std::string temp = "<= ";
  $$.place = strdup(temp.c_str());
  $$.code = strdup(empty);
}
| GTE
{
  std::string temp = ">= ";
  $$.place = strdup(temp.c_str());
  $$.code = strdup(empty);
};

Ident:      IDENT
{
  $$.place = strdup($1);
  $$.code = strdup(empty);;
};
LocalIdent:      IDENT
{
  // Check for redeclaration (test 04) TODO same name as program
  std::string variable($1);
  if (variables.find(variable) != variables.end()) {
    char temp[128];
    snprintf(temp, 128, "Redeclaration of variable %s", variable.c_str());
    yyerror(temp);
  }
  else {
    variables.insert(std::pair<std::string,int>(variable,0));
  }
  $$.place = strdup($1);
  $$.code = strdup(empty);;
};
FunctionIdent: IDENT
{
  if (functions.find(std::string($1)) != functions.end()) {
    char temp[128];
    snprintf(temp, 128, "Redeclaration of function %s", $1);
    yyerror(temp);
  }
  else {
    functions.insert(std::pair<std::string,int>($1,0));
  }
  $$.place = strdup($1);
  $$.code = strdup(empty);;
}
%%

void yyerror(const char* s) {
   printf("ERROR: %s at symbol \"%s\" on line %d, col %d\n", s, yytext, Ln, Col);
}

std::string newTemp() {
  static int num = 0;
  std::string temp = "__temp__" + std::to_string(num++);
  return temp;
}

std::string newLabel() {
  static int num = 0;
  std::string temp = "__label__" + std::to_string(num++);
  return temp;
}
		 
