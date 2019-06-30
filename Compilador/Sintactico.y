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
int IndTake;

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

/**** INICIO EXP NUMERICA ****/

int buscarTipoTS(char* nombreVar);
void verificarTipoDato(int tipo);
void reiniciarTipoDato();
int tipoDatoActual = -1;

int Integer = 1;
int Float = 2;
int String = 3;
/**** FIN EXP NUMERICA ****/

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
int usadofibo=0;
/**** FIBONACCI ****/

/**** TAKE ****/
int takeRESULTADO = 0; //Variable que tendra el resultado final del take.
int takeORDEN = 0; //La primer constante de la lista del take.
int takeHASTA = 0; //La CTE del Take que determina cuantos elementos, empezando del primero intervienen en el take.
int takeAUX = 0; //Variable auxiliar que contendra los subresultados del take.
char takeOP[2]; //Variable auxiliar que contendra el operador del take.
int takeLISTAVACIA = 0; //Variable auxiliar que indica si la lista del take esta vacia.
int usadotake=0;

/**** TAKE ****/

/**** print y scan ****/
int IndEntrada;
int IndSalida;
/**** fin print y scanf ****/


/**** Inicio assembler ****/
char lista_operandos_assembler[100][100];
int cant_op = 0;

void genera_asm();
char* getNombreAsm(char *cte_o_id);
char* getCodOp(char*);
void insertarVariablesAuxilaresTDS();
/**** Fin assembler ****/
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

programa: declaracion {} bloque
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

fibonacci: FIBONACCI P_A CTE_INT P_C { usadofibo=1; numFibo=$3; }


take: 	TAKE P_A takeOp PUNTO_COMA CTE_INT {takeHASTA =$5; takeLISTAVACIA = 0;} PUNTO_COMA C_A takelist C_C P_C 
		{
			usadotake=1;
			IndTake = crearTerceto_cii(takeOP, terceto_index-1, terceto_index-2);
			crearTerceto_ccc("N", "", "");
			takeRESULTADO = crearTerceto_cii("=", terceto_index-1, IndTake);
		}
		
		;
takeOp:		OP_SUMA {strcpy(takeOP, "+");}
			| OP_RESTA {strcpy(takeOP, "-");}  
			| OP_MULT {strcpy(takeOP, "*");}  
			| OP_DIV {strcpy(takeOP, "/");} 

takelist: 	takelist PUNTO_COMA CTE_INT 
			{
				if(takeHASTA > 0 && takeORDEN%2 == 0) 
				{
					IndTake = crearTerceto_icc($3, "", "");
					takeORDEN++;
					takeHASTA--;
				}
				else if(takeHASTA > 0 && takeORDEN%2 == 1)
				{
					IndTake = crearTerceto_cii(takeOP, IndTake-1, IndTake);
					takeORDEN++;
					takeHASTA--;
					IndTake = crearTerceto_icc($3, "", "");
					IndTake = crearTerceto_cii(takeOP, IndTake-1, IndTake);
				}
			}
			| CTE_INT //Por esta regla pasa solo una vez.
			{
				if(takeHASTA>0)
				{
					IndTake = crearTerceto_icc($1, "", "");
					takeHASTA--;
				}
			}
			| {takeLISTAVACIA=1;} //Si la lista esta vacia lo indico en un flag a tratar despues.
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
	  | take 			  { IndFactor = takeRESULTADO;}
	  ;
	  
constante: CTE_INT    { IndFactor = crearTerceto_icc($1, "", ""); }  
         | CTE_STRING { IndFactor = crearTerceto_ccc($1, "", ""); }  
		 | CTE_REAL   { IndFactor = crearTerceto_fcc($1, "", ""); }
		 ;

entrada: GET ID		{ 		existe_en_ts($2);
							  IndEntrada = crearTerceto_ccc($2, "", ""); 
							  crearTerceto_cic("GET",IndEntrada,"");
							}
       ;
	   
salida: DISPLAY CTE_STRING	{ IndSalida = crearTerceto_ccc($2, "", "");
							  crearTerceto_cic("DISPLAY",IndSalida,"");
							}
      | DISPLAY ID 			{ existe_en_ts($2);
							  IndSalida = crearTerceto_ccc($2, "", "");
							  crearTerceto_cic("DISPLAY",IndSalida,""); 
							}
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
	insertarVariablesAuxilaresTDS();
	save_reg_ts();
	printf("Tabla de simbolos guardada en ts.txt\n");
	save_tercetos();
	printf("Tercetos guardados en intermedia.txt\n");
	genera_asm();
	printf("Assembler guardado en final.asm\n");
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

int buscarTipoTS(char* nombreVar) {

	int pos = nombre_existe_en_ts(nombreVar);
	if (pos == -1) {
		
		char *nomCte = (char*) malloc(31*sizeof(char));
		*nomCte = '\0';
		strcat(nomCte, "_");
		strcat(nomCte, nombreVar);
	
		char *original = nomCte;
		while(*nomCte != '\0') {
			if (*nomCte == ' ' || *nomCte == '"' || *nomCte == '!' 
				|| *nomCte == '.') {
				*nomCte = '_';
			}
			nomCte++;
		}
		nomCte = original;

		int pos = nombre_existe_en_ts(nomCte);
		if (pos == -1) {
			yyerror("La variable no fue declarada");
		}
	}
	
	return tipoDeDato(pos);

}


/**** INICIO TERCETOS ****/
/**** INICIO TERCETOS ****/
int crearTerceto_ccc(char *uno, char *dos, char *tres) {
	struct terceto terc;
	int index = terceto_index;
	terc.uno = malloc(sizeof(char)*strlen(uno)+1);
	strcpy(terc.uno, uno);
	terc.dos = malloc(sizeof(char)*strlen(dos)+1);
	strcpy(terc.dos, dos);
	terc.tres = malloc(sizeof(char)*strlen(tres)+1);
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
	//printf("\n apilando %d", dato);
    p->pila[p->tope] = dato;
    p->tope++;
    return 1;
}

int sacarDePila(Pila *p){
    if( p->tope == 0){
        return 0;
    }
	//printf("\n desapilando %d",p->pila[p->tope]);
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

void insertarVariablesAuxilaresTDS(){
	//(char *nombre, char *tipo, char *valor, char *longitud)
	
	
	//Variables usadas en Fibonacci
	if(usadofibo == 1){
		insertar_tabla_simbolos("fibo","INT","","-");
		insertar_tabla_simbolos("n1","INT","","-");
		insertar_tabla_simbolos("n2","INT","","-");
		insertar_tabla_simbolos("cont","INT","","-");
	}
	
	
	//Variables usadas en TAKE
	if(usadotake == 1){
		insertar_tabla_simbolos("N","INT","","-");
	}	
}


void genera_asm()
{
	int cont=0;
	char* file_asm = "Final.asm";
	FILE* pf_asm;
	char aux[10];
	
	int lista_etiquetas[1000];
	int cant_etiquetas = 0;
	char etiqueta_aux[10];

	char ult_op1_cmp[30];
	strcpy(ult_op1_cmp, "");
	char op1_guardado[30];

	if((pf_asm = fopen(file_asm, "w")) == NULL)
	{
		printf("Error al generar el asembler \n");
		exit(1);
	}
	 /* generamos el principio del assembler, que siempre es igual */

	 fprintf(pf_asm, "include macros2.asm\n");
	 fprintf(pf_asm, "include number.asm\n");
	 fprintf(pf_asm, ".MODEL	LARGE \n");
	 fprintf(pf_asm, ".386\n");
	 fprintf(pf_asm, ".STACK 200h \n");

	 fprintf(pf_asm, ".CODE \n");
	 fprintf(pf_asm, "MAIN:\n");
	 fprintf(pf_asm, "\n");

    fprintf(pf_asm, "\n");
    fprintf(pf_asm, "\t MOV AX,@DATA 	;inicializa el segmento de datos\n");
    fprintf(pf_asm, "\t MOV DS,AX \n");
    fprintf(pf_asm, "\t MOV ES,AX \n");
    fprintf(pf_asm, "\t FNINIT \n");;
    fprintf(pf_asm, "\n");

	int i, j;
	int opSimple,  // Formato terceto (x,  ,  ) 
		opUnaria,  // Formato terceto (x, x,  )
		opBinaria; // Formato terceto (x, x, x)
	int agregar_etiqueta_final_nro = -1;
	
	// Guardo todos los tercetos donde tendría que poner etiquetas
	for(i = 0; i < terceto_index; i++)
	{
		if (strcmp(tercetos[i].dos, "") != 0 && strcmp(tercetos[i].tres, "") ==0)
		{
			if (strcmp(tercetos[i].uno, "READ") != 0 && strcmp(tercetos[i].uno, "WRITE") != 0)
			{
				int found = -1;
				int j;
				for (j = 1; j<=cant_etiquetas; j++)
				{
					if (lista_etiquetas[j] == atoi(tercetos[i].dos))
					{
						found = 1;
					}
				}
				if (found == -1) 
				{
					cant_etiquetas++;
					lista_etiquetas[cant_etiquetas] = atoi(tercetos[i].dos);
				}
			}
		}	
	}
	
	// Armo el assembler
	for (i = 0; i < terceto_index; i++) 
	{
		//printf("TERCETO NUMERO %d \n", i);

		if (strcmp("", tercetos[i].dos) == 0) {
			opSimple = 1;
			opUnaria = 0;
			opBinaria = 0;
		} else if (strcmp("", tercetos[i].tres) == 0) {
			opSimple = 0;
			opUnaria = 1;
			opBinaria = 0;
		} else {
			opSimple = 0; 
			opUnaria = 0;
			opBinaria = 1;
		}

		for (j=1;j<=cant_etiquetas;j++) {
			if (i == lista_etiquetas[j])
			{
				sprintf(etiqueta_aux, "ETIQ_%d", lista_etiquetas[j]);
				fprintf(pf_asm, "%s: \n", etiqueta_aux);
			}
		}
		if (opSimple == 1) {
			// Ids, constantes
			cant_op++;
			strcpy(lista_operandos_assembler[cant_op], tercetos[i].uno);
		} 
		else if (opUnaria == 1) {
			// Saltos, write, read
			if (strcmp("WRITE", tercetos[i].uno) == 0) 
			{	
				int tipo = buscarTipoTS(tercetos[atoi(tercetos[i].dos)].uno);
				if (tipo == Float) 
				{
					fprintf(pf_asm, "\t DisplayFloat %s,2 \n", getNombreAsm(tercetos[atoi(tercetos[i].dos)].uno));
				}
				else if (tipo == Integer) 
				{
					fprintf(pf_asm, "\t DisplayFloat %s,2 \n", getNombreAsm(tercetos[atoi(tercetos[i].dos)].uno));
				} else 
				{
					fprintf(pf_asm, "\t DisplayString %s \n", getNombreAsm(tercetos[atoi(tercetos[i].dos)].uno));
				}
				// Siempre inserto nueva linea despues de mostrar msj
				fprintf(pf_asm, "\t newLine \n");
			}
			else if (strcmp("READ", tercetos[i].uno) == 0) 
			{
				int tipo = buscarTipoTS(tercetos[atoi(tercetos[i].dos)].uno);
				if (tipo == Float) 
				{
					fprintf(pf_asm, "\t GetFloat %s\n", getNombreAsm(tercetos[atoi(tercetos[i].dos)].uno));
				} 
				else if (tipo == Integer) 
				{
					// pongo getfloat para manejar todo con fld en las operaciones
					fprintf(pf_asm, "\t GetFloat %s\n", getNombreAsm(tercetos[atoi(tercetos[i].dos)].uno));
				}	
				else 
				{
					fprintf(pf_asm, "\t GetString %s\n", getNombreAsm(tercetos[atoi(tercetos[i].dos)].uno));
				}
			}
			else // saltos
			{
				//printf("TERCETO NUMERO %d \n", i);
				char *codigo = getCodOp(tercetos[i].uno);
				sprintf(etiqueta_aux, "ETIQ_%d", atoi(tercetos[i].dos));
				if (atoi(tercetos[i].dos) >= terceto_index) 
				{
					agregar_etiqueta_final_nro = atoi(tercetos[i].dos);
				}
				fflush(pf_asm); 
				fprintf(pf_asm, "\t %s %s \t;Si cumple la condicion salto a la etiqueta\n", codigo, etiqueta_aux);
			}
 		}
		else {
			// Expresiones ; Comparaciones ; Asignacion
			char *op2 = (char*) malloc(100*sizeof(char));
			strcpy(op2, lista_operandos_assembler[cant_op]);
			cant_op--;

			char *op1 = (char*) malloc(100*sizeof(char));
			if (strcmp(tercetos[i].uno, "CMP" ) == 0 && strcmp(ult_op1_cmp, tercetos[i].dos) == 0 )
			{
				strcpy(op1, op1_guardado);
			}
			else 
			{
				strcpy(op1, lista_operandos_assembler[cant_op]); 
				cant_op--;
				strcpy(op1_guardado, op1);
			}
			
			if (strcmp(tercetos[i].uno, "=" ) == 0)
			{
				fprintf(pf_asm, "\t FLD %s \t;Cargo valor \n", getNombreAsm(op1));
				fprintf(pf_asm, "\t FSTP %s \t; Se lo asigno a la variable que va a guardar el resultado \n", getNombreAsm(op2));
			}
			else if (strcmp(tercetos[i].uno, "CMP" ) == 0)
			{
				fprintf(pf_asm, "\t FLD %s\t\t;comparacion, operando1 \n", getNombreAsm(op1));
				fprintf(pf_asm, "\t FLD %s\t\t;comparacion, operando2 \n", getNombreAsm(op2));
				fprintf(pf_asm, "\t FCOMP\t\t;Comparo \n");
				fprintf(pf_asm, "\t FFREE ST(0) \t; Vacio ST0\n");
				fprintf(pf_asm, "\t FSTSW AX \t\t; mueve los bits C a FLAGS\n");
				fprintf(pf_asm, "\t SAHF \t\t\t;Almacena el registro AH en el registro FLAGS \n");

				strcpy(ult_op1_cmp, tercetos[i].dos);
			}
			else
			{
				sprintf(aux, "_aux%d", i); // auxiliar relacionado al terceto
				insertar_ts_si_no_existe(aux, "REAL", "", "");
				fflush(pf_asm);
				fprintf(pf_asm, "\t FLD %s \t;Cargo operando 1\n", getNombreAsm(op1));
				fprintf(pf_asm, "\t FLD %s \t;Cargo operando 2\n", getNombreAsm(op2));
				fflush(pf_asm);

				fprintf(pf_asm, "\t %s \t\t;Opero\n", getCodOp(tercetos[i].uno));
				fprintf(pf_asm, "\t FSTP %s \t;Almaceno el resultado en una var auxiliar\n", getNombreAsm(aux));
				
				cant_op++;
				strcpy(lista_operandos_assembler[cant_op], aux);
			}
			
		}
	}


	if(agregar_etiqueta_final_nro != -1) {
		sprintf(etiqueta_aux, "ETIQ_%d", agregar_etiqueta_final_nro);
		fprintf(pf_asm, "%s: \n", etiqueta_aux);
	}

	/*generamos el final */
	fprintf(pf_asm, "\t mov AX, 4C00h \t ; Genera la interrupcion 21h\n");
	fprintf(pf_asm, "\t int 21h \t ; Genera la interrupcion 21h\n");

	generaSegmDatosAsm(pf_asm);

	fprintf(pf_asm, "END MAIN\n");
	fclose(pf_asm);


}

/************************************************************************************************************/
char* getCodOp(char* token)
{
	if(!strcmp(token, "+"))
	{
		return "FADD";
	}
	else if(!strcmp(token, "="))
	{
		return "MOV";
	}
	else if(!strcmp(token, "-"))
	{
		return "FSUB";
	}
	else if(!strcmp(token, "*"))
	{
		return "FMUL";
	}
	else if(!strcmp(token, "/"))
	{
		return "FDIV";
	}
	else if(!strcmp(token, "BNE"))
	{
		return "JNE";
	}
	else if(!strcmp(token, "BEQ"))
	{
		return "JE";
	}
	else if(!strcmp(token, "BGE"))
	{
		return "JNA";
	}
	else if(!strcmp(token, "BGT"))
	{
		return "JNAE";
	}
	else if(!strcmp(token, "BLE"))
	{
		return "JNB";
	}
	else if(!strcmp(token, "BLT"))
	{
		return "JNBE";
	}
	else if (!strcmp(token, "BI")) {
		return "JMP";
	}
	else
		return token;
}

/*
	Obtiene los nombres para assembler
*/
char* getNombreAsm(char *cte_o_id) {
	//char nombreAsm[200];
	char* nombreAsm = (char*) malloc(200);
	nombreAsm[0] = '\0';
	strcat(nombreAsm, "@"); // prefijo agregado
	
	int pos = nombre_existe_en_ts(cte_o_id);
	if (pos==-1) { //si no lo encuentro con el mismo nombre es porque debe ser cte		
		char *nomCte = (char*) malloc(31*sizeof(char));
		*nomCte = '\0';
		strcat(nomCte, "_");
		strcat(nomCte, cte_o_id);
	
		char *original = nomCte;
		while(*nomCte != '\0') {
			if (*nomCte == ' ' || *nomCte == '"' || *nomCte == '!' 
				|| *nomCte == '.') {
				*nomCte = '_';
			}
			nomCte++;
		}
		nomCte = original;
		strcat(nombreAsm, nomCte);
	} else {
		strcat(nombreAsm, cte_o_id);
	}
	
	return nombreAsm;
}