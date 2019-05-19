%{
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>
#include "y.tab.h"

FILE *yyin;
char *yytext;
extern int yylineno;

/**** DEC VARIABLES ****/
char tipoActual[10]={""};
char listaVariables[10][20]={""};
int variableActual=0;
void reinicioVariables();
/**** DEC VARIABLES ****/


/**** INICIO TERCETOS ****/
//Indices de los tercetos
int IndAsignacion;
int IndExpresion;
int IndTermino;
int IndFactor;
int IndInlist;
int IndEntrada;
int IndSalida;

//Estructura del terceto
struct terceto {
	char *uno;
	char *dos;
	char *tres;
};
struct terceto tercetos[1000];
int terceto_index = 0;

int crearTerceto_ccc(char *uno, char *dos, char *tres);	//terceto con 3 chars
int crearTerceto_cci(char *uno, char *dos, int tres);	//terceto con dos chars y un entero
int crearTerceto_cii(char *uno, int dos, int tres);	//terceto con un char y dos enteros
int crearTerceto_fcc(float uno, char *dos, char *tres);	//terceto con un float y dos chars
int crearTerceto_icc(int uno, char *dos, char *tres);	//terceto con un entero y dos char
int crearTerceto_cic(char *uno, int dos, char *tres);	//terceto con un char, un int y otro char

void save_tercetos();
/**** FIN TERCETOS ****/

/**** INICIO PILA ****/
const int tamPila = 100;

typedef struct {
    int pila[100];
    int tope;
} Pila;

void crearPila( Pila *p);
int pilaLLena( Pila *p );
int pilaVacia( Pila *p);
int ponerEnPila(Pila *p, int dato);
int sacarDePila(Pila *p);

Pila pilaExpresion;
Pila pilaTermino;
/**** FIN PILA ****/

/**** INICIO COMPARACION ****/
char valor_comparacion[3];
int IndComparacion;
int saltos_and_a_completar[6];
int and_index = 0;
void completar_salto_si_es_comparacion_AND(int pos);
int pos_a_completar_OR;
int es_negado = 0;
/**** FIN COMPARACION ****/

/**** INICIO IF ****/
int if_salto_a_completar;
int if_saltos[6];
int if_index = 0;
void if_guardar_salto(int pos);
void if_completar_ultimo_salto_guardado_con(int pos);
/**** FIN IF ****/


/**** INICIO WHILE ****/
int while_pos_inicio;
int while_salto_a_completar;
int while_pos_a_completar[11];
int while_index = 0;
void while_guardar_pos(int pos);
/**** FIN WHILE ****/

/**** FIBONACCI ****/
int generarFibonacci(int num);
int numFibo=0;

/**** FIBONACCI ****/

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
		
sentencia: asignacion PUNTO_COMA	{  }
		 | iteracion  				{  }
		 | decision   				{  }
		 | entrada PUNTO_COMA   	{  }
		 | salida PUNTO_COMA    	{  }
		 | take PUNTO_COMA	  		{  }
		 | fibonacci PUNTO_COMA 	{  }
		 ;
		 
asignacion: ID ASIG expresion { IndAsignacion = crearTerceto_cii("=", crearTerceto_ccc($1, "",""), IndExpresion); }
		  ;

iteracion: WHILE P_A { while_guardar_pos(terceto_index); }
			condicion P_C { if(strcmp(valor_comparacion, "") != 0) while_guardar_pos(crearTerceto_ccc(valor_comparacion, "", "")); else while_index++; }
			bloque ENDWHILE {
				char *salto = (char*) malloc(sizeof(int));
				itoa(terceto_index+1, salto, 10);
				tercetos[while_pos_a_completar[while_index]].dos = salto;
				while_index--;
				crearTerceto_cic("BI", while_pos_a_completar[while_index], "");
				while_index--;
				completar_salto_si_es_comparacion_AND(terceto_index);

				}
		 ;
		
decision: IF P_A condicion P_C 
	{ if(strcmp(valor_comparacion, "") != 0) 
	if_guardar_salto(crearTerceto_ccc(valor_comparacion, "", ""));
	else if_index++; }
			 decision_bloque
		;

decision_bloque:
		  bloque ENDIF {
			if_completar_ultimo_salto_guardado_con(terceto_index);
			completar_salto_si_es_comparacion_AND(terceto_index);

			}
		| bloque { if_completar_ultimo_salto_guardado_con(terceto_index+1);
			       completar_salto_si_es_comparacion_AND(terceto_index+1);
				   if_guardar_salto(crearTerceto_ccc("BI", "",""));

				}
		  ELSE bloque ENDIF { if_completar_ultimo_salto_guardado_con(terceto_index); }
		;

condicion: condicion: comparacion { and_index++; saltos_and_a_completar[and_index] = -1;}
         | comparacion {and_index++; 
					saltos_and_a_completar[and_index] = crearTerceto_ccc(valor_comparacion, "", "");
						} AND comparacion
		 | comparacion {
				and_index++; 
				saltos_and_a_completar[and_index] = -1;
				crearTerceto_cic(valor_comparacion, terceto_index+2, "");
				pos_a_completar_OR = crearTerceto_ccc("BI","",""); 
				}
			OR comparacion {
				char *salto = (char*) malloc(sizeof(int));
				itoa(terceto_index+1, salto, 10);
				tercetos[pos_a_completar_OR].dos = (char*) malloc(sizeof(char)*strlen(salto));
				strcpy(tercetos[pos_a_completar_OR].dos, salto);
			}

		 | NOT { es_negado = 1; } P_A comparacion P_C { es_negado = 0; }
		 ;
		 


comparacion: expresion { IndComparacion = IndExpresion; } 
				MENOR expresion { crearTerceto_cii("CMP", IndComparacion, IndExpresion);
				if(es_negado == 0) { strcpy(valor_comparacion, "BGE"); } else { strcpy(valor_comparacion, "BLT"); }}
		   | expresion { IndComparacion = IndExpresion; }
				MENOR_IGUAL expresion { crearTerceto_cii("CMP", IndComparacion, IndExpresion);
				if(es_negado == 0) { strcpy(valor_comparacion, "BGT"); } else { strcpy(valor_comparacion, "BLE"); }
			 }
		   | expresion { IndComparacion = IndExpresion; }
				MAYOR expresion { crearTerceto_cii("CMP", IndComparacion, IndExpresion);
		   		if(es_negado == 0) { strcpy(valor_comparacion, "BLE"); } else { strcpy(valor_comparacion, "BGT"); }
			 }
		   | expresion { IndComparacion = IndExpresion; }
				MAYOR_IGUAL expresion { crearTerceto_cii("CMP", IndComparacion, IndExpresion);
		   		if(es_negado == 0) { strcpy(valor_comparacion, "BLT"); } else { strcpy(valor_comparacion, "BGE"); }
			 }
		   | expresion { IndComparacion = IndExpresion; }
				IGUAL expresion { crearTerceto_cii("CMP", IndComparacion, IndExpresion);
		   		if(es_negado == 0) { strcpy(valor_comparacion, "BNE"); } else { strcpy(valor_comparacion, "BEQ"); }
			 }
		   | expresion { IndComparacion = IndExpresion; }
				DISTINTO expresion { crearTerceto_cii("CMP", IndComparacion, IndExpresion);
		   		if(es_negado == 0) { strcpy(valor_comparacion, "BEQ"); } else { strcpy(valor_comparacion, "BNE"); }
			 }                  
		   ; 

fibonacci: FIBONACCI P_A CTE_INT P_C { numFibo=$3; }


take: 	TAKE P_A takeOp PUNTO_COMA CTE_INT PUNTO_COMA C_A takelist C_C P_C {  }
		
		;
takeOp:		OP_SUMA | OP_RESTA | OP_MULT | OP_DIV

takelist: 	takelist PUNTO_COMA CTE_INT
			| CTE_INT
			|
			;
		  
expresion: expresion OP_SUMA termino  { IndExpresion = crearTerceto_cii("+", IndExpresion, IndTermino); }
		 | expresion OP_RESTA termino { IndExpresion = crearTerceto_cii("-", IndExpresion, IndTermino); }
		 | termino	{ IndExpresion = IndTermino; }
		 ;
		 
termino: termino OP_MULT factor  { IndTermino = crearTerceto_cii("*", IndTermino, IndFactor); }
	   | termino OP_DIV factor   { IndTermino = crearTerceto_cii("/", IndTermino, IndFactor); }
	   | factor                  { IndTermino = IndFactor; }
	   ;
	   
factor: ID	               { IndFactor = crearTerceto_ccc($1, "", ""); }
	  | constante		   
	  | P_A {    ponerEnPila(&pilaTermino, IndTermino);
                 ponerEnPila(&pilaExpresion, IndExpresion);
            }
        expresion P_C  {
                            IndFactor = IndExpresion;
                            IndExpresion = sacarDePila(&pilaExpresion);
                            IndTermino = sacarDePila(&pilaTermino);
                        }
	  | fibonacci 		  { IndFactor = generarFibonacci(numFibo); }
	  | take 			  {  }
	  ;
	  
constante: CTE_INT    { IndFactor = crearTerceto_icc($1, "", ""); }  
         | CTE_STRING { IndFactor = crearTerceto_ccc($1, "", ""); }  
		 | CTE_REAL   { IndFactor = crearTerceto_fcc($1, "", ""); }
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
	crearPila(&pilaExpresion);
    crearPila(&pilaTermino);
	yyparse();
	//mostrar_ts();
	save_reg_ts();
	save_tercetos();
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


/**** INICIO TERCETOS ****/
/**** INICIO TERCETOS ****/
int crearTerceto_ccc(char *uno, char *dos, char *tres) {
	struct terceto terc;
	int index = terceto_index;
	terc.uno = malloc(sizeof(char)*strlen(uno));
	strcpy(terc.uno, uno);
	terc.dos = malloc(sizeof(char)*strlen(dos));
	strcpy(terc.dos, dos);
	terc.tres = malloc(sizeof(char)*strlen(tres));
	strcpy(terc.tres, tres);
	tercetos[index] = terc;
	terceto_index++;
	return index; // devuelvo la pos del terceto creado
}

int crearTerceto_cci(char *uno, char *dos, int tres) {
	char *tres_char = (char*) malloc(sizeof(int));
	itoa(tres, tres_char, 10);

	return crearTerceto_ccc(uno, dos, tres_char);
}

int crearTerceto_cii(char *uno, int dos, int tres) {
	struct terceto terc;
	int index = terceto_index;

	char *dos_char = (char*) malloc(sizeof(int));
	itoa(dos, dos_char, 10);

	return crearTerceto_cci(uno, dos_char, tres);
}

int crearTerceto_fcc(float uno, char *dos, char *tres) {
	char *uno_char = (char*) malloc(sizeof(float));
	snprintf(uno_char, sizeof(float), "%f", uno);

	return crearTerceto_ccc(uno_char, dos, tres);
}

int crearTerceto_icc(int uno, char *dos, char *tres) {
	char *uno_char = (char*) malloc(sizeof(int));
	itoa(uno, uno_char, 10);

	return crearTerceto_ccc(uno_char, dos, tres);
}

int crearTerceto_cic(char *uno, int dos, char *tres) {
	char *dos_char = (char*) malloc(sizeof(int));
	itoa(dos, dos_char, 10);

	return crearTerceto_ccc(uno, dos_char, tres);
}

void save_tercetos() {
	FILE *file = fopen("Intermedia.txt", "a");

	if(file == NULL)
	{
    	printf("(!) ERROR: No se pudo abrir el txt correspondiente a la generacion de codigo intermedio\n");
	}
	else
	{
		int i = 0;
		for (i;i<terceto_index;i++) {
			// printf("%d (%s, %s, %s)\n", i, tercetos[i].uno, tercetos[i].dos, tercetos[i].tres);
			fprintf(file, "%d (%s, %s, %s)\n", i, tercetos[i].uno, tercetos[i].dos, tercetos[i].tres);
		}
		fclose(file);
	}
}

/**** FIN. TERCETOS ****/
/**** FIN. TERCETOS ****/

/**** PILA ****/
/**** PILA ****/

void crearPila( Pila *p){
    p->tope = 0;
}

int pilaLLena( Pila *p ){
    return p->tope == tamPila;
}

int pilaVacia( Pila *p){
    return p->tope == tamPila;
}

int ponerEnPila(Pila *p, int dato){
    if( p->tope == 100){
        return 0;
    }
	printf("\n apilando %d", dato);
    p->pila[p->tope] = dato;
    p->tope++;
    return 1;
}

int sacarDePila(Pila *p){
    if( p->tope == 0){
        return 0;
    }
	printf("\n desapilando %d",p->pila[p->tope]);
    p->tope--;
    return p->pila[p->tope];
}
/**** FIN PILA ****/
/**** FIN PILA ****/



/* Basicamente una mini-pila para anidar ifs*/
void if_guardar_salto(int pos) {
	if (if_index < 6)
	{
		if_index++;
		if_saltos[if_index] = pos;
	}
	else
	{
		yyerror("No se puede tener más de 5 ifs anidados\n");
	}
}

/* Desapilar anidaciones de ifs */
void if_completar_ultimo_salto_guardado_con(int pos) {
	char *salto = (char*) malloc(sizeof(int));
	itoa(pos, salto, 10);
	tercetos[if_saltos[if_index]].dos = (char*) malloc(sizeof(char)*strlen(salto));
	strcpy(tercetos[if_saltos[if_index]].dos, salto);
	if_index--;
}

/* Funcion para simil apilar las pos del while */
void while_guardar_pos(int pos) {
	if (if_index < 11) // se usa del 1 al 10 y se ocupan dos pos por cada while
	{
		while_index++;
		while_pos_a_completar[while_index] = pos;
	}
	else
	{
		yyerror("No se puede tener más de 5 whiles anidados");
	}
}

/* Si el flag de AND esta prendido completa la pos guardada y vuelve el flag a off */
void completar_salto_si_es_comparacion_AND(int pos) {
		if (saltos_and_a_completar[and_index] == -1){
			and_index--; // flags usados para mantener la correlatividad de la pila de if con la de and
		}
		else {
			char *salto = (char*) malloc(sizeof(int));
			itoa(pos, salto, 10);
			tercetos[saltos_and_a_completar[and_index]].dos = (char*) malloc(sizeof(char)*strlen(salto));
			strcpy(tercetos[saltos_and_a_completar[and_index]].dos, salto);
			and_index--;
		}

}

/*** BASICAMENTE ES UN CHORIZO DE TERCETOS QUE HACE EL FIBONACCI***/

int generarFibonacci(int num){
	char auxnum[10];
	sprintf(auxnum,"%d",num);
	
	//si me llega un 0, retorno 1, creo que era asi la serie..
	if(num == 0)
		return crearTerceto_icc(1,"","");
	
	crearTerceto_ccc(auxnum,"","");
	crearTerceto_ccc("cont","","");
	crearTerceto_cii("=",terceto_index-1,terceto_index-2);
	crearTerceto_icc(0,"","");
	crearTerceto_ccc("n1","","");
	crearTerceto_cii("=",terceto_index-1,terceto_index-2);
	crearTerceto_icc(1,"","");
	crearTerceto_ccc("n2","","");
	crearTerceto_cii("=",terceto_index-1,terceto_index-2);
	crearTerceto_ccc("n1","","");						//saltar aca si tengo q seguir comparando
	crearTerceto_ccc("n2","","");
	crearTerceto_cii("+",terceto_index-1,terceto_index-2);
	crearTerceto_ccc("fibo","","");
	crearTerceto_cii("=",terceto_index-1,terceto_index-2);
	crearTerceto_icc(1,"","");
	crearTerceto_ccc("cont","","");
	crearTerceto_cii("-",terceto_index-1,terceto_index-2);
	crearTerceto_ccc("cont","","");
	crearTerceto_cii("=",terceto_index-1,terceto_index-2);
	crearTerceto_icc(0,"","");
	crearTerceto_ccc("cont","","");
	crearTerceto_cii("CMP",terceto_index-1,terceto_index-2);
	crearTerceto_cic("BEQ",terceto_index+8,"");
	crearTerceto_ccc("n2","","");
	crearTerceto_ccc("n1","","");
	crearTerceto_cii("=",terceto_index-1,terceto_index-2);
	crearTerceto_ccc("fibo","","");
	crearTerceto_ccc("n2","","");
	crearTerceto_cii("=",terceto_index-1,terceto_index-2);
	crearTerceto_cic("BI",terceto_index-20,"");
	
	return crearTerceto_ccc("fibo","","");
}
