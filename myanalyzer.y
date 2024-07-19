%{
	#include <stdio.h>
	#include <string.h>
  	#include "cgen.h"
	#include <math.h>

    #define maxVariables 20
    #define maxVarLength 20
	
	extern int yylex(void);
	extern int line_num;

    char* compString = "";
    char* compPointers = "";
    char ident_table[maxVariables][maxVarLength];
    int ident_counter = 0;
%}

%union {
	char* str;
}

%token <str> TK_STRING
%token <str> TK_IDENTIFIER
%token <str> TK_REAL 
%token <str> TK_INTEGER

%token KW_INTEGER
%token KW_SCALAR
%token KW_STR
%token KW_BOOL
%token KW_TRUE
%token KW_FALSE
%token KW_CONST
%token KW_IF
%token KW_ENDIF
%token KW_FOR
%token KW_IN
%token KW_ENDFOR
%token KW_WHILE
%token KW_ENDWHILE
%token KW_BREAK
%token KW_CONTINUE
%token KW_NOT
%token KW_AND
%token KW_ELSE
%token KW_OR
%token KW_DEF
%token KW_ENDDEF
%token KW_MAIN
%token KW_RETURN
%token KW_COMP
%token KW_ENDCOMP
%token KW_OF

%token OP_PLUS
%token OP_MINUS
%token OP_MULTIPLY
%token OP_DIVIDE
%token OP_MODULO
%token OP_POWER

%token OP_EQUALS
%token OP_NOTEQUALS
%token OP_LESS
%token OP_LESSEQUALS
%token OP_GREATER
%token OP_GREATEREQUALS

%token OP_ASSIGN
%token OP_PLUSASSIGN
%token OP_MINUSASSIGN
%token OP_MULTIPLYASSIGN
%token OP_DIVIDEASSIGN
%token OP_MODULOASSIGN
%token OP_COLONASSIGN


%token SEMICOLON
%token LEFT_PARENTHESIS
%token RIGHT_PARENTHESIS
%token COMMA
%token LEFT_BRACKET
%token RIGHT_BRACKET
%token COLON
%token DOT
%token RIGHT_ARROW
%token HASHTAG

%start input

%type <str> contents basic_types expression identifier declarations assignments arguments general_rules statement 
%type <str> constant constant_list initialize_constant array_cases
%type <str> declare_function func_with_return func_without_return main_function function_call function_skeleton function_var
%type <str> comp_function comp_arguments comp_struct comp_body hashtag_ident hashtag_var


//Priorities - The lower we get, the higher the priority

%left HASHTAG
%right OP_ASSIGN OP_PLUSASSIGN OP_MINUSASSIGN OP_MULTIPLYASSIGN OP_DIVIDEASSIGN OP_MODULOASSIGN OP_COLONASSIGN
%left KW_OR
%left KW_AND
%right KW_NOT
%left OP_EQUALS OP_NOTEQUALS
%left OP_LESS OP_LESSEQUALS OP_GREATER OP_GREATEREQUALS
%left OP_PLUS OP_MINUS 
%left OP_MULTIPLY OP_DIVIDE OP_MODULO
%right OP_POWER
%left  DOT LEFT_BRACKET RIGHT_BRACKET LEFT_PARENTHESIS RIGHT_PARENTHESIS

%%

//RULES

input: 
	contents  
	{
		if (yyerror_count == 0) {
            printf("//==================COMPILED PROGRAM IN C==================\n");
      		puts(c_prologue); //include lamdalib.h from cgen.c
			printf("%s\n", $1);	
		}
	}
	;

contents: 
    %empty              		{$$ = template("\n");}
    | contents constant     {$$ = template("%s%s", $1, $2);}
    | contents declarations    {$$ = template("%s%s", $1, $2);}
    | contents declare_function     {$$ = template("%s%s", $1, $2);}
	| contents main_function    {$$ = template("%s%s", $1, $2);}
    | contents comp_struct  {$$ = template("%s%s", $1, $2);}
    ;

constant:
    KW_CONST constant_list COLON basic_types SEMICOLON {$$ = template("const %s %s;\n", $4, $2);}
    ;

constant_list:
    initialize_constant {$$ = $1;}
    | constant_list COMMA initialize_constant {$$ = template("%s, %s", $1, $3);}
    ;

initialize_constant:
    TK_IDENTIFIER OP_ASSIGN expression {$$ = template("%s = %s", $1, $3);}
    ;

basic_types:  
    KW_BOOL      {$$ = template("int");} //since we have no boolean types in C
    | KW_INTEGER        {$$ = template("int");}
	| KW_STR        {$$ = template("StringType");}
    | KW_SCALAR     {$$ = template("double");} 
    | TK_IDENTIFIER      {$$ = template("%s", $1);}
    ;

expression:
    TK_IDENTIFIER { $$ = $1; }
    | TK_STRING { $$ = $1; }
    | TK_INTEGER { $$ = $1; }
    | TK_REAL { $$ = $1; }
    | KW_TRUE { $$ = "1"; }
    | KW_FALSE { $$ = "0"; }
    | expression KW_AND expression { $$ = template("%s && %s", $1, $3); }
    | KW_NOT expression { $$ = template("!%s", $2); } %prec KW_NOT
    | expression KW_OR expression { $$ = template("%s || %s", $1, $3); }
	| function_call { $$ = $1; }
    | assignments { $$ = $1; }
    | TK_IDENTIFIER LEFT_BRACKET TK_IDENTIFIER RIGHT_BRACKET { $$ = template("%s[%s]", $1, $3); }
    | OP_PLUS expression %prec OP_PLUS {$$ = template("+%s", $2);}
    | OP_MINUS expression %prec OP_MINUS {$$ = template("-%s", $2);}
    | OP_MODULO expression { $$ = template("%%%s", $2); }
    | expression OP_PLUS expression { $$ = template("%s + %s", $1, $3); }
    | expression OP_MINUS expression { $$ = template("%s - %s", $1, $3); }
    | expression OP_MULTIPLY expression { $$ = template("%s * %s", $1, $3); }
    | expression OP_DIVIDE expression { $$ = template("%s / %s", $1, $3); }
    | expression OP_MODULO expression { $$ = template("%s %% %s", $1, $3); }
    | expression OP_POWER expression { $$ = template("pow(%s, %s)", $1, $3); }
    | expression OP_EQUALS expression { $$ = template("%s == %s", $1, $3); }
    | expression OP_NOTEQUALS expression { $$ = template("%s != %s", $1, $3); }
    | expression OP_LESS expression { $$ = template("%s < %s", $1, $3); }
    | expression OP_LESSEQUALS expression { $$ = template("%s <= %s", $1, $3); }
    | expression OP_GREATER expression { $$ = template("%s > %s", $1, $3); }
    | expression OP_GREATEREQUALS expression { $$ = template("%s >= %s", $1, $3); }
    | LEFT_PARENTHESIS expression RIGHT_PARENTHESIS { $$ = template("(%s)", $2); }
    | expression DOT TK_IDENTIFIER { $$ = template("%s.%s", $1, $3); }
    | HASHTAG expression { $$ = template("self->%s", $2); }
    | expression DOT HASHTAG TK_IDENTIFIER { 
        int var = 0;
        for (int i = 0; i < ident_counter; i++) {
            if (strcmp(ident_table[i], $4) == 0) {
                var = 1;
                break;
            }
        }
        if (var) {
            $$ = template("%s.self->%s", $1, $4);
        } else {
            $$ = template("%s.%s", $1, $4);
        }

    }
    ;

identifier:
	TK_IDENTIFIER {$$ = $1;}
    | TK_IDENTIFIER COMMA identifier {$$ = template("%s , %s", $1, $3);} //x, y, z, etc..
    ;


declarations:
    identifier COLON basic_types SEMICOLON {$$ = template("%s %s;\n", $3, $1);}
    | TK_IDENTIFIER LEFT_BRACKET RIGHT_BRACKET COLON basic_types SEMICOLON  {$$ = template("%s %s[];\n", $5, $1);}
    | TK_IDENTIFIER LEFT_BRACKET TK_INTEGER RIGHT_BRACKET COLON basic_types SEMICOLON  {$$ = template("%s %s[%s];\n", $6, $1, $3);}
	;



assignments:
    TK_IDENTIFIER LEFT_BRACKET TK_IDENTIFIER RIGHT_BRACKET OP_ASSIGN expression { $$ = template("%s[%s] = %s", $1, $3, $6); } //array[index] = value;
    | HASHTAG TK_IDENTIFIER LEFT_BRACKET HASHTAG TK_IDENTIFIER RIGHT_BRACKET OP_ASSIGN expression { $$ = template("self->%s[self->%s] = %s", $2, $5, $8); } //self->object[self->index] = value;
    | TK_IDENTIFIER OP_ASSIGN expression {$$ = template("%s = %s", $1, $3);} //variable = value;
    | expression DOT HASHTAG TK_IDENTIFIER OP_ASSIGN expression {$$ = template("%s.%s = %s", $1, $4, $6);} //object.field = value;
    | expression OP_PLUSASSIGN expression { $$ = template("%s += %s", $1, $3); } //variable += value;
    | expression OP_MINUSASSIGN expression { $$ = template("%s -= %s", $1, $3); } //variable -= value;
    | expression OP_MULTIPLYASSIGN expression { $$ = template("%s *= %s", $1, $3); } //variable *= value;
    | expression OP_DIVIDEASSIGN expression { $$ = template("%s /= %s", $1, $3); } //variable /= value;
    | expression OP_MODULOASSIGN expression { $$ = template("%s %%= %s", $1, $3); } //variable %= value;
    ;


declare_function:
    func_with_return
    | func_without_return
    ;

func_with_return:
    KW_DEF TK_IDENTIFIER LEFT_PARENTHESIS arguments RIGHT_PARENTHESIS RIGHT_ARROW basic_types COLON function_skeleton KW_ENDDEF SEMICOLON {
        $$ = template("%s %s (%s) {\n%s\n}\n\n", $7, $2, $4, $9);
    }
    ;

func_without_return:
    KW_DEF TK_IDENTIFIER LEFT_PARENTHESIS arguments RIGHT_PARENTHESIS COLON function_skeleton KW_ENDDEF SEMICOLON {
        $$ = template("void %s (%s) {\n%s\n}\n\n", $2, $4, $7);
    }
    ;


main_function:
    KW_DEF KW_MAIN LEFT_PARENTHESIS RIGHT_PARENTHESIS COLON function_skeleton KW_ENDDEF SEMICOLON {$$ = template("int main() {\n%s}\n", $6);}
    ;

function_call:
    TK_IDENTIFIER LEFT_PARENTHESIS RIGHT_PARENTHESIS { $$ = template("%s()", $1); } //foo()
    | TK_IDENTIFIER LEFT_PARENTHESIS function_var RIGHT_PARENTHESIS { $$ = template("%s(%s)", $1, $3); } //foo(x,y)
    | expression DOT TK_IDENTIFIER LEFT_PARENTHESIS RIGHT_PARENTHESIS {
        if($1[0] == '#') {
            $$ = template("%s.%s(&%s)", $1, $3, $1); //#obj.method() -> obj.method(&obj)
        } else {
           $$ = template("%s.%s()", $1, $3); 
        }    
    }
    | expression DOT TK_IDENTIFIER LEFT_PARENTHESIS function_var RIGHT_PARENTHESIS {
        if($1[0] == '#') {
            $$ = template("%s.%s(&%s, %s)", $1, $3, $1, $5); //obj.method() -> obj.method(&obj, x, y)
        } else {
           $$ = template("%s.%s(%s)", $1, $3, $5); 
        }
    }
    ;

function_var:
    expression                 	{$$ = $1;}
    |expression COMMA function_var	{$$ = template("%s , %s", $1, $3);}
    ;

function_skeleton: //recursive 
    %empty                 		            {$$ = template("");}   
    | constant function_skeleton            {$$ = template("\t%s%s", $1, $2);} 
    | declarations function_skeleton        {$$ = template("\t%s%s", $1, $2);} 
    | hashtag_var function_skeleton      {$$ = template("\t%s%s", $1, $2);}
    | general_rules function_skeleton        {$$ = template("\t%s%s", $1, $2);}
    | array_cases function_skeleton       {$$ = template("\t%s%s", $1, $2);}
    ;

array_cases: //issue here
    TK_IDENTIFIER OP_COLONASSIGN LEFT_BRACKET expression KW_FOR TK_IDENTIFIER COLON TK_INTEGER RIGHT_BRACKET COLON basic_types SEMICOLON {
        $$ = template("%s* %s=(%s*)malloc(%s * sizeof(%s)); \nfor (int %s = 0 ; %s <= %s ; %s++) {\n\t%s[%s]=%s;\n}\n", $11, $1, $11, $8, $11, $6, $6, $8, $6, $1, $6, $6);
    }
    | TK_IDENTIFIER OP_COLONASSIGN LEFT_BRACKET expression KW_FOR TK_IDENTIFIER COLON basic_types KW_IN TK_IDENTIFIER KW_OF TK_INTEGER RIGHT_BRACKET COLON basic_types SEMICOLON{
        $$ = template("%s* %s=(%s*)malloc(%s * sizeof(%s)); \nfor (int i = 0 ; i <= %s ; i++) {\n\t%s[i]=%s[i];\n}\n", $15, $1, $15, $12, $15, $12, $1, $10);
    }
    ;

arguments:
    %empty                                  							                {$$ = template("");}
    | TK_IDENTIFIER COLON basic_types 											        {$$ = template("%s %s", $3, $1);}
    | TK_IDENTIFIER LEFT_BRACKET RIGHT_BRACKET COLON basic_types    					{$$ = template("%s* %s", $5, $1);}
    | TK_IDENTIFIER COLON basic_types COMMA arguments        							{$$ = template("%s %s, %s", $3, $1, $5);}
    | TK_IDENTIFIER LEFT_BRACKET RIGHT_BRACKET COLON basic_types COMMA arguments 		{$$ = template("%s* %s, %s", $5, $1, $7);}
    ;

general_rules: 
    expression SEMICOLON {$$ = template("%s;\n", $1);}
    //if without else
	| KW_IF LEFT_PARENTHESIS expression RIGHT_PARENTHESIS COLON statement KW_ENDIF SEMICOLON {$$ = template("if (%s) {\n\t%s\n}\n", $3, $6);}
    //if with else
    | KW_IF LEFT_PARENTHESIS expression RIGHT_PARENTHESIS COLON statement KW_ELSE COLON statement KW_ENDIF SEMICOLON {$$ = template("if (%s) {\n\t%s\n} else {\n\t%s\n}\n", $3, $6, $9);}
    //for without step
    | KW_FOR TK_IDENTIFIER KW_IN LEFT_BRACKET expression COLON expression RIGHT_BRACKET COLON statement KW_ENDFOR SEMICOLON {$$ = template("for (int %s = %s ; %s <= %s ; %s++) {\n\t%s\n}\n", $2, $5, $2, $7, $2, $10);}
    //for with step
    | KW_FOR TK_IDENTIFIER KW_IN LEFT_BRACKET expression COLON expression COLON expression RIGHT_BRACKET COLON statement KW_ENDFOR SEMICOLON {$$ = template("for  (int %s = %s ; %s <= %s ; %s += %s) {\n\t%s\n}\n", $2, $5, $2, $7, $2, $9, $12);}
    //while loop
    | KW_WHILE LEFT_PARENTHESIS expression RIGHT_PARENTHESIS COLON statement KW_ENDWHILE SEMICOLON {$$ = template("while ( %s ) {\n\t%s\n}\n", $3, $6);}
    //break statement
    | KW_BREAK SEMICOLON {$$ = template("break;\n");}
    //continue statement
    | KW_CONTINUE SEMICOLON {$$ = template("continue;\n");}
    //return
    | KW_RETURN SEMICOLON {$$ = template("return;\n");}
    //return expr.
    | KW_RETURN expression SEMICOLON {$$ = template("return %s;\n", $2);}
    ;	

statement:
	general_rules           {$$ = $1;}
    | general_rules statement   {$$ = template("\t%s %s", $1, $2);}
    ;
//----------------COMP IMPLEMENTATION---------------------------
comp_function:
    KW_DEF TK_IDENTIFIER LEFT_PARENTHESIS RIGHT_PARENTHESIS COLON function_skeleton KW_ENDDEF SEMICOLON 
    {
        $$ = template("void (*%s) (SELF); \n", $2);
        compString = template("%s\n void %s(SELF ){\n\t %s} \n", compString, $2, $6);

        if (compPointers == "")
            compPointers = template(".%s=%s", $2, $2);
        else 
            compPointers = template("%s, .%s=%s", compPointers, $2, $2);
    }
    | KW_DEF TK_IDENTIFIER LEFT_PARENTHESIS RIGHT_PARENTHESIS COLON SEMICOLON KW_ENDDEF SEMICOLON
    {
        $$ = template("void (*%s) (SELF ); \n", $2);
        compString = template("%s\nvoid %s(SELF ){\n;\n} \n", compString, $2);

        if (compPointers == "")
            compPointers = template(".%s=%s", $2, $2);
        else 
            compPointers = template("%s, .%s=%s", compPointers, $2, $2);
    }
    | KW_DEF TK_IDENTIFIER LEFT_PARENTHESIS comp_arguments RIGHT_PARENTHESIS COLON function_skeleton KW_ENDDEF SEMICOLON 
    {
        $$ = template("void (*%s) (SELF, %s); \n", $2, $4);
        compString = template("%s\n void %s(SELF, %s){\n\t %s} \n", compString, $2, $4, $7);

        if (compPointers == "")
            compPointers = template(".%s=%s", $2, $2);
        else 
            compPointers = template("%s, .%s=%s", compPointers, $2, $2);
    }
    | KW_DEF TK_IDENTIFIER LEFT_PARENTHESIS RIGHT_PARENTHESIS RIGHT_ARROW basic_types COLON function_skeleton KW_ENDDEF SEMICOLON 
    {
        $$ = template("%s (*%s)(SELF ) \n", $6, $2);
        compString = template("%s\n%s %s(SELF ){\n\t %s} \n", compString, $6, $2, $8);

        if (compPointers == "")
            compPointers = template(".%s=%s", $2, $2);
        else 
            compPointers = template("%s, .%s=%s", compPointers, $2, $2);
    }
    | KW_DEF TK_IDENTIFIER LEFT_PARENTHESIS comp_arguments RIGHT_PARENTHESIS RIGHT_ARROW basic_types COLON function_skeleton KW_ENDDEF SEMICOLON 
    {
        $$ = template("%s (*%s)(SELF, %s) \n", $7, $2, $4);
        compString = template("%s\n%s %s(SELF, %s){\n\t %s} \n", compString, $7, $2, $4, $9);
        
        if (compPointers == "")
            compPointers = template(".%s=%s", $2, $2);
        else 
            compPointers = template("%s, .%s=%s", compPointers, $2, $2);
    }
    ;

comp_arguments:
    TK_IDENTIFIER COLON basic_types {$$ = template("%s %s", $3, $1);}
    | TK_IDENTIFIER COLON basic_types COMMA comp_arguments {$$ = template("%s %s, %s", $3, $1, $5);}
    | TK_IDENTIFIER LEFT_BRACKET RIGHT_BRACKET COLON basic_types {$$ = template("%s* %s", $5, $1);}
    | TK_IDENTIFIER LEFT_BRACKET RIGHT_BRACKET COLON basic_types COMMA comp_arguments {$$ = template("%s* %s, %s", $5, $1, $7);}
    ;

comp_struct:
    KW_COMP TK_IDENTIFIER COLON comp_body KW_ENDCOMP SEMICOLON 
    {
        $$ = template("#define SELF struct %s *self \n typedef struct %s {\n%s\n} %s; \n%s\n const %s ctor_%s = {%s};\n #undef SELF\n\n", $2, $2, $4, $2, compString, $2, $2, compPointers);
        compString = "";
        compPointers = "";
        for (int i = 0; i < maxVariables; i++) {
            ident_table[i][0] = '\0';
        }
        ident_counter = 0;
    }
    ;

comp_body:
    %empty {$$ = template("\n");}
    | hashtag_var comp_body {$$ = template("\t%s%s", $1, $2);}
    | comp_function comp_body {$$ = template("\t%s%s", $1, $2);}
    | general_rules comp_body {$$ = template("\t%s%s", $1, $2);}
    ;


hashtag_ident: //identifiers that begin with #
	HASHTAG TK_IDENTIFIER {
        $$ = template("%s", $2);
        strncpy(ident_table[ident_counter], template("%s", $2), maxVarLength);
        ident_table[ident_counter++][maxVarLength - 1] = '\0'; // Ensure null-termination
    }
	| HASHTAG TK_IDENTIFIER OP_ASSIGN expression {
        $$ = template("%s = %s", $2, $4);
        strncpy(ident_table[ident_counter], template("%s", $2), maxVarLength);
        ident_table[ident_counter++][maxVarLength - 1] = '\0'; // Ensure null-termination
    }
    | HASHTAG TK_IDENTIFIER COMMA hashtag_ident {
        $$ = template("%s , %s", $2, $4);
        strncpy(ident_table[ident_counter], template("%s", $2), maxVarLength);
        ident_table[ident_counter++][maxVarLength - 1] = '\0'; // Ensure null-termination
    }
    | HASHTAG TK_IDENTIFIER OP_ASSIGN expression COMMA hashtag_ident {
        $$ = template("%s = %s , %s", $2, $4, $6);
        strncpy(ident_table[ident_counter], template("%s", $2), maxVarLength);
        ident_table[ident_counter++][maxVarLength - 1] = '\0'; // Ensure null-termination
    }
    ;

hashtag_var: //variables that begin with #
    hashtag_ident COLON basic_types SEMICOLON {$$ = template("%s %s;\n", $3, $1);}
    | HASHTAG TK_IDENTIFIER LEFT_BRACKET TK_INTEGER RIGHT_BRACKET COLON basic_types SEMICOLON  {$$ = template("%s %s[%s];\n", $7, $2, $4);}
    | HASHTAG TK_IDENTIFIER LEFT_BRACKET RIGHT_BRACKET COLON basic_types SEMICOLON  {$$ = template("%s %s[];\n", $6, $2);}
	;

%%
int main ()
{
   if ( yyparse() == 0 )
		printf("//Accepted!\n");
	else
		printf("Rejected!\n");
}
