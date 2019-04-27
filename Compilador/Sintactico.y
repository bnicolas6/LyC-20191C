%{
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>
#include "y.tab.h"

FILE *yyin;
char *yytext;
extern int yylineno;
char tipoActual[10]={""};
char listaVariables[10][20]={""};
int variableActual=0;
void reinicioVariables();

%}

%union {
int intVal;
double realVal;
char *strVal;
}

%token <strVal>ID <intVal>CTE_INT <strVal>CTE_STRING <realVal>CTE_REAL
%token ASIG OP_SUMA OP_RESTA OP_MULT OP_DIV
%token MENOR MAYOR IGUAL DISTINTO MENOR_IGUAL MAYOR_IGUAL
%token FIBONACCI
%token TAKE
%token WHILE ENDWHILE
%token IF ELSE ENDIF
%token P_A P_C C_A C_C
%token COMA PUNTO_COMA DOS_PUNTOS
%token AND OR NOT
%token INT FLOAT STRING 
%token DECVAR ENDDEC
%token GET DISPLAY

%start start

%%

start: programa { printf("\n\n\tCOMPILACION EXITOSA!!\n\n\n"); }
	 |			{ printf("\n El archivo 'Prueba.Txt' no tiene un programa\n"); }
	 ;

programa: declaracion { printf("Declaracion OK\n"); } bloque
        | bloque
		;
		
declaracion: DECVAR def_variables ENDDEC
		   | DECVAR ENDDEC
		   ;
		   
def_variables: def_variables def_var { printf("\n sint: def variables\n"); };
				| def_var;	   
		   
def_var: tipo DOS_PUNTOS listavar{ guardarTipos(variableActual, listaVariables, tipoActual); reinicioVariables(); }  
         ;

listavar: listavar PUNTO_COMA ID { strcpy(listaVariables[variableActual++],$3); insertar_id_en_ts($3); }
	    | ID { strcpy(listaVariables[variableActual++],$1); insertar_id_en_ts($1); } 
        ;
	
tipo: INT    { strcpy(tipoActual,"INT"); }
    | FLOAT  { strcpy(tipoActual,"REAL"); }
	| STRING { strcpy(tipoActual,"STRING"); }
	;
		
bloque: sentencia
	  | bloque sentencia
	  ;
		
sentencia: asignacion { printf("Asignacion OK\n"); }
		 | iteracion  { printf("Iteracion OK\n"); }
		 | decision   { printf("Decision OK\n"); }
		 | entrada    { printf("Entrada OK\n"); }
		 | salida     { printf("Salida OK\n"); }
		 | take 	  { printf("Take OK\n"); }
		 | fibonacci  { printf("Fibonacci OK\n"); }
		 ;
		 
asignacion: ID ASIG expresion PUNTO_COMA
		  ;

iteracion: WHILE P_A condicion P_C bloque ENDWHILE
		 ;
		
decision: IF P_A condicion P_C bloque ENDIF
		| IF P_A condicion P_C bloque ELSE bloque ENDIF
		;

condicion: comparacion
         | comparacion AND comparacion 
		 | comparacion OR comparacion
		 | NOT comparacion
		 | NOT P_A comparacion P_C
		 ;

comparacion: expresion MENOR expresion       { printf("Condicion menor OK\n"); }
		   | expresion MENOR_IGUAL expresion { printf("Condicion menor o igual OK\n"); }
		   | expresion MAYOR expresion       { printf("Condicion mayor OK\n"); }
		   | expresion MAYOR_IGUAL expresion { printf("Condicion mayor o igual OK\n"); }
		   | expresion IGUAL expresion       { printf("Condicion igual OK\n"); }
		   | expresion DISTINTO expresion    { printf("Condicion distinto OK\n"); }                   
		   ; 

fibonacci: FIBONACCI P_A CTE_INT P_C


take: 	TAKE P_A OP_SUMA PUNTO_COMA CTE_INT PUNTO_COMA C_A takelist C_C P_C { printf("Take suma OK\n"); }
		| TAKE P_A OP_RESTA PUNTO_COMA CTE_INT PUNTO_COMA C_A takelist C_C P_C { printf("Take resta OK\n"); }
		| TAKE P_A OP_MULT PUNTO_COMA CTE_INT PUNTO_COMA C_A takelist C_C P_C { printf("Take multi OK\n"); }
		| TAKE P_A OP_DIV PUNTO_COMA CTE_INT PUNTO_COMA C_A takelist C_C P_C { printf("Take div OK\n"); }
		;

takelist: 	takelist PUNTO_COMA CTE_INT
			| CTE_INT
			|
			;
		  
expresion: expresion OP_SUMA termino  { printf("Suma OK\n"); }
		 | expresion OP_RESTA termino { printf("Resta OK\n"); }
		 | termino
		 ;
		 
termino: termino OP_MULT factor { printf("Multiplicacion OK\n"); }
	   | termino OP_DIV factor	{ printf("Division OK\n"); }
	   | factor
	   ;
	   
factor: ID	              { existe_en_ts($1); printf("ID es: %s\n",yylval.strVal); }  
	  | constante
	  | P_A expresion P_C
	  | fibonacci 		  { printf("Fibonacci OK\n"); }
	  | take 			  { printf("Take OK\n"); }
	  ;
	  
constante: CTE_INT    { printf("ENTERO es: %d\n",yylval.intVal); }  
         | CTE_STRING { printf("STRING es: %s\n",yylval.strVal); }  
		 | CTE_REAL   { printf("REAL es: %.2f\n",yylval.realVal); }
		 ;

entrada: GET ID
       ;
	   
salida: DISPLAY CTE_STRING
      | DISPLAY ID 			{ existe_en_ts($2); }
	  ;
	  
%%

int main(int argc,char *argv[])
{
  
  if ((yyin = fopen(argv[1], "rt")) == NULL)
  {
	printf("\nNo se puede abrir el archivo: %s\n", argv[1]);
  }
  else
  {
	yyparse();
	//mostrar_ts();
	save_reg_ts();
	printf("Listo TS\n");
  }
  fclose(yyin);
  return 0;
}

int yyerror(char *errMessage)
{
   printf("(!) ERROR en la linea %d: %s\n",yylineno,errMessage);
   fprintf(stderr, "Fin de ejecucion.\n");
   system ("Pause");
   exit (1);
}

void reinicioVariables() {
	variableActual=0;
    strcpy(tipoActual,"");
}


