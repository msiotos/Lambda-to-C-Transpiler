%{
  #include <stdio.h>
  #include <string.h>
  #include "cgen.h"	
  #include <math.h>
  #include "myanalyzer.tab.h"
  
  int line_num = 1; /* Keep track of the line number */

#define MAX_MACROS 20 /* We define the maximum number of macros allowed */
char* macro_table[MAX_MACROS][2]; /* We define a table to store macro names and their definitions */
int macro_table_size = 0; /* Initialize the current size of the macro table */

int define_macro(char* macro_name, char* macro_definition); /* Function to define a macro */
char* get_macro_definition(char* macro_name); /* Function to get the definition of a macro */


%}


ID      	[a-zA-Z][0-9a-zA-Z_]*
INTEGER    	([0])|([1-9][0-9]*)
DECIMAL   ("."{INTEGER})|({INTEGER}("."{INTEGER}?)?)
REAL      {DECIMAL}([eE][+-]?{INTEGER})?
CHARACTER [., a-zA-Z0-9\-+\*\/:_$%!#@&~^()]|[\\n]|[\\t]|[\\r]|[\\\\][\\"]
STRING 		\"{CHARACTER}*\"

/* We define a lexer state for processing macro definitions */
%x macro_state 

%%

@defmacro[ \r\t]+       BEGIN(macro_state);
<macro_state>{ID}       {
							/* Rule to start processing a macro definition */
							/* We store the macro name */
    						char* macro_name = strdup(yytext);
    						char* macro_value = NULL;
    						size_t macro_value_length = 0;
    						char next_char;
							/* Create a memory stream to store the macro definition */
    						FILE* macro_file = open_memstream(&macro_value, &macro_value_length);
							/* Read characters until the end of the line */
						    while((next_char = input()) != '\n')
       						fputc(next_char, macro_file);
    						fclose(macro_file);
							/* We define the macro and handle any errors */
    						if(!define_macro(macro_name, macro_value))
        					yyerror("Failed to define macro '%s'\n", macro_name);

    						BEGIN(INITIAL); /* Return to the initial state */
						};


integer     return KW_INTEGER;
scalar      return KW_SCALAR;
str         return KW_STR;
bool        return KW_BOOL;
True        return KW_TRUE;
False       return KW_FALSE;
const       return KW_CONST;
if          return KW_IF;
else		return KW_ELSE;
endif		return KW_ENDIF;
for		    return KW_FOR;
in		    return KW_IN;
endfor		return KW_ENDFOR;
while		return KW_WHILE;
endwhile	return KW_ENDWHILE;
break		return KW_BREAK;
continue	return KW_CONTINUE;
not		    return KW_NOT;
and		    return KW_AND;
or		    return KW_OR;
def		    return KW_DEF;
enddef		return KW_ENDDEF;
main		return KW_MAIN;
return		return KW_RETURN;
comp		return KW_COMP;
endcomp		return KW_ENDCOMP;
of		    return KW_OF;

{ID}  		{
			/* Rule to handle identifiers and check if they are defined macros */
	    	/* Get the macro definition if it exists */
			char* macro_definition = get_macro_definition(yytext);
			if(macro_definition == NULL) {
        	yylval.str = strdup(yytext);
        	return TK_IDENTIFIER; /* Return the identifier token if not a macro */
    		}
			/* Push the macro definition back into the input stream */
			for(int i = strlen(macro_definition); i > 0; i--) {
        	unput(macro_definition[i-1]);
   			}
			} 
{STRING}    { yylval.str = strdup(yytext); return TK_STRING; }
{INTEGER}    { yylval.str = strdup(yytext); return TK_INTEGER; }
{REAL}      { yylval.str = strdup(yytext); return TK_REAL; }

"+"     { return OP_PLUS; } /* arithmetic operators */
"-"     { return OP_MINUS; }
"*"     { return OP_MULTIPLY; }
"/"     { return OP_DIVIDE; }
"%"     { return OP_MODULO; }
"**"    { return OP_POWER; }


"=="    { return OP_EQUALS; } /* relational operators */
"!="    { return OP_NOTEQUALS; }
"<"     { return OP_LESS; }
"<="    { return OP_LESSEQUALS; }
">"     { return OP_GREATER; }
">="    { return OP_GREATEREQUALS; }


"="     { return OP_ASSIGN; } /* assignment operators */
"+="    { return OP_PLUSASSIGN; }
"-="    { return OP_MINUSASSIGN; }
"*="    { return OP_MULTIPLYASSIGN; }
"/="    { return OP_DIVIDEASSIGN; }
"%="    { return OP_MODULOASSIGN; }
":="  	{ return OP_COLONASSIGN; }


";"   { return SEMICOLON; } /* delimiters */
"("   { return LEFT_PARENTHESIS; }
")"   { return RIGHT_PARENTHESIS; }
","   { return COMMA; }
"["   { return LEFT_BRACKET; }
"]"   { return RIGHT_BRACKET; }
":"   { return COLON; }
"."   { return DOT; }
"->"  { return RIGHT_ARROW; }
"#"   { return HASHTAG; }



[ \r\t]+     /* eat whitespace */
"--"[^\n]*   /* eat line comments */

\n 					 ++line_num;

<<EOF>> 	return EOF;
.         { yyerror("Lectical error: '%s' not recognised \n", yytext);}
%%


int define_macro(char* macro_name, char* macro_definition)
{
    int i;
	/* Check if the macro is already defined and update it */
    for(i = 0; i < macro_table_size; i++) {
        if(strcmp(macro_table[i][0], macro_name) == 0) {
            free(macro_name);
            free(macro_table[i][1]);
            macro_table[i][1] = macro_definition;
            break;
        }
    }
	/* If macro was updated, return 1 equals success */
    if(i < macro_table_size)
        return 1;
	/* If the macro is new and there's space in the table, add it */
    else if(macro_table_size < MAX_MACROS) {
        assert(i == macro_table_size);
        macro_table[i][0] = macro_name;
        macro_table[i][1] = macro_definition;
        macro_table_size++;
        return 1;
    }
	/* If the table is full, return 0 equals failure */
    else
        return 0;
}

char* get_macro_definition(char* macro_name)
{
    for(int i = 0; i < macro_table_size; i++) {
        if(strcmp(macro_table[i][0], macro_name) == 0)
            return macro_table[i][1];
    }
    return NULL; /* Return NULL if macro was not found */
}
