/* Task 1: Create a flex specification to recognize tokens in the calculator language.
 * Print out an error message and exit if any unrecognized character is encountered in the input.
 * Use flex to compile your specification into an executable lexical analyzer that reads
 * text from standard-in and prints the identified tokens to the screen, one token per line.
 */


%%
[0-9]	       printf("DIGIT\n");
"-"            printf("MINUS\n");
"+"            printf("PLUS\n"); 
"*"            printf("MULT\n"); 
"/"            printf("DIV\n"); 
"="            printf("EQUAL\n"); 
"("            printf("L_PAREN\n");
")"            printf("R_PAREN\n");

%%

main()
{
  yylex();
}

