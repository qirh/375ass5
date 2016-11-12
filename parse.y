%{     /* pars1.y    Pascal Parser      Gordon S. Novak Jr.  ; 30 Jul 13   */

/* Copyright (c) 2013 Gordon S. Novak Jr. and
   The University of Texas at Austin. */

/* 14 Feb 01; 01 Oct 04; 02 Mar 07; 27 Feb 08; 24 Jul 09; 02 Aug 12 */

/*
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program; if not, see <http://www.gnu.org/licenses/>.
  */


/* NOTE:   Copy your lexan.l lexical analyzer to this directory.      */

       /* To use:
                     make pars1y              has 1 shift/reduce conflict
                     pars1y                   execute the parser
                     i:=j .
                     ^D                       control-D to end input

                     pars1y                   execute the parser
                     begin i:=j; if i+j then x:=a+b*c else x:=a*b+c; k:=i end.
                     ^D

                     pars1y                   execute the parser
                     if x+y then if y+z then i:=j else k:=2.
                     ^D

           You may copy pars1.y to be parse.y and extend it for your
           assignment.  Then use   make parser   as above.
        */

        /* Yacc reports 1 shift/reduce conflict, due to the ELSE part of
           the IF statement, but Yacc's default resolves it in the right way.*/

#include <stdio.h>
#include <ctype.h>
#include "token.h"
#include "lexan.h"
#include "symtab.h"
#include "parse.h"
#include <string.h>


        /* define the type of the Yacc stack element to be TOKEN */

#define YYSTYPE TOKEN

TOKEN parseresult;


%}

/* Order of tokens corresponds to tokendefs.c; do not change */

%token IDENTIFIER STRING NUMBER   /* token types */

%token PLUS MINUS TIMES DIVIDE    /* Operators */
%token ASSIGN EQ NE LT LE GE GT POINT DOT AND OR NOT DIV MOD IN

%token COMMA                      /* Delimiters */
%token SEMICOLON COLON LPAREN RPAREN LBRACKET RBRACKET DOTDOT

%token ARRAY BEGINBEGIN           /* Lex uses BEGIN */
%token CASE CONST DO DOWNTO ELSE END FILEFILE FOR FUNCTION GOTO IF LABEL NIL
%token OF PACKED PROCEDURE PROGRAM RECORD REPEAT SET THEN TO TYPE UNTIL
%token VAR WHILE WITH

%error-verbose
%%

  program   : PROGRAM IDENTIFIER LPAREN id_list RPAREN SEMICOLON cblock DOT  
                                                        { printdeubg("1 program\n"); parseresult = makeprogram($2, $4, $7); }
            ;
  variable  : IDENTIFIER                                { printdeubg("1 variable\n"); $$ = findid($1); }
            ;
  id_list   : IDENTIFIER COMMA id_list                  { printdeubg("1 id_list\n"); $$ = cons($1, $3); }
            | IDENTIFIER                                { printdeubg("2 id_list\n"); $$ = cons($1, NULL); }
            ;  
  type      : simple_type                               { printdeubg("1 type\n"); }
          //  | ARRAY LBRACKET simple_type_list RBRACKET OF type { printdeubg("2 type\n"); $$ = NULL; }
          //  | POINT IDENTIFIER                          { printdeubg("3 type\n"); $$ = NULL; }
            ;  
  cdef      : IDENTIFIER EQ constant                    { printdeubg("1 cdef\n"); instconst($1, $3); }
            ;
  cdef_list : cdef SEMICOLON cdef_list                  { printdeubg("1 cdef_list\n"); cons($1, $3); }
            | cdef SEMICOLON                            { printdeubg("2 cdef_list\n"); cons($1, NULL); }
            ;
  cblock    : CONST cdef_list vblock                    { printdeubg("1 cblock\n"); $$ = $3; }
            | vblock
            ;
  constant  : IDENTIFIER                                { printdeubg("1 constant\n"); }
            | NUMBER                                    { printdeubg("2 constant\n"); }
            | STRING                                    { printdeubg("3 constant\n"); } 
            | sign NUMBER                               { printdeubg("4 constant\n"); }
            | sign IDENTIFIER                           { printdeubg("5 constant\n"); }
            ;
  simple_type: IDENTIFIER                               { printdeubg("1 simple_type\n"); $$ = findtype($1); }
           // | LPAREN id_list RPAREN                     { printdeubg("2 simple_type\n"); $$ = NULL; }
           // | NUMBER DOTDOT NUMBER /*NUMBER|constant?*/ { printdeubg("3 simple_type\n"); $$ = NULL; }
            ;
  simple_type_list : simple_type COMMA simple_type_list { printdeubg("1 simple_type_list\n"); $$ = cons($3, $1); }
                   | simple_type                        { printdeubg("2 simple_type_list\n"); }
                   ;
  block     : BEGINBEGIN statement endpart              { printdeubg("1 block\n"); $$ = makeprogn($1, cons($2, $3));  }
            ;
  vblock    : VAR vdef_list block                       { printdeubg("1 vblock\n"); $$ = $3; }
            | block                                     { printdeubg("2 vblock\n"); }
            ; 
  vdef_list : vdef SEMICOLON vdef_list                  { printdeubg("1 vdef_list\n"); cons($1, $3); }
            | vdef                                      { printdeubg("2 vdef_list\n"); }  
            | vdef SEMICOLON                            { printdeubg("3 vdef_list\n"); }  
            ;
  vdef      : id_list COLON type                        { printdeubg("1 vdef\n"); instvars($1, $3); printdeubg("1 vdef end\n"); }
            ;
  funcall   : IDENTIFIER LPAREN expr_list RPAREN        { printdeubg("1 funcall\n"); $$ = makefuncall(talloc(), $1, $3); }
            ;
  statement : BEGINBEGIN statement endpart              { printdeubg("1 statement\n"); $$ = makeprogn($1, cons($2, $3)); }
            | NUMBER COLON statement                    { printdeubg("2 statement\n"); $$ = NULL; }
            | assignment                                { printdeubg("3 statement\n"); }
            | funcall                                   { printdeubg("4 statement\n"); }
            | IF expression THEN statement endif        { printdeubg("5 statement\n"); $$ = makeif($1, $2, $4, $5); }
            | FOR assignment TO expression DO statement { printdeubg("6 statement\n"); $$ = makefor(1, $1, $2, $3, $4, $5, $6); }
            | REPEAT statement_list UNTIL expression    { printdeubg("8 statement\n"); $$ = makerepeat($1, $2, $3, $4); }
            | IDENTIFIER LPAREN args RPAREN             { printdeubg("9 statement\n"); $$ = makefuncall($2, $1, $3); }
            ;
  statement_list: statement SEMICOLON statement_list    { printdeubg("1 statement_list\n"); $$ = cons($1, $3); }
            | statement                                 { printdeubg("1 statement_list\n"); }
            ;
  endpart   : SEMICOLON statement endpart               { printdeubg("1 endpart\n"); $$ = cons($2, $3); }
            | END                                       { printdeubg("2 endpart\n"); $$ = NULL; }
            ;
  endif     : ELSE statement                            { printdeubg("1 endif\n"); $$ = $2; }
            | /* empty */                               { printdeubg("2 endif\n"); $$ = NULL; }
            ;
  assignment: variable ASSIGN expression                { printdeubg("1 assignment\n"); $$ = binop($2, $1, $3); }
            ;
  expression: expression compare_op term                { printdeubg("1 expression\n"); $$ = binop($2, $1, $3); }
            | expression compare_op simple_expression   { printdeubg("2 expression\n"); $$ = binop($2, $1, $3); }
            | simple_expression                         { printdeubg("3 expression\n"); }
            | term                                      { printdeubg("4 expression\n"); }
            ;
  simple_expression: simple_expression sign term        { printdeubg("1 simple_expression\n"); $$ = binop($2, $1, $3); }
            | term                                      { printdeubg("2 simple_expression\n"); }
            | sign term                                 { printdeubg("3 simple_expression\n"); $$ = unaryop($1, $2); }
            | STRING                                    { printdeubg("4 simple_expression\n"); }
            ;
  expr_list : expression COMMA expr_list                { printdeubg("1 expr_list\n"); $$ = cons($1, $3); }
            | expression                                { printdeubg("2 expr_list\n"); }
            ;
  term      : term times_op factor                      { printdeubg("1 term\n"); $$ = binop($2, $1, $3); }
            | factor                                    { printdeubg("2 term\n"); }
            ;
  factor    : LPAREN expression RPAREN                  { printdeubg("1 factor\n"); $$ = $2; }
            | variable                                  { printdeubg("2 factor\n"); }
            | NUMBER                                    { printdeubg("3 factor\n"); }    
            | funcall                                   { printdeubg("4 factor\n"); }   
            ;
  args      : expression COMMA args                     { printdeubg("1 args\n"); $$ = cons($1, $3); }
            | expression                                { printdeubg("2 args\n"); $$ = cons($1, NULL); }
            ;
  compare_op: EQ                                        { printdeubg("1 compare_op\n"); }
            | LT                                        { printdeubg("2 compare_op\n"); }
            | GT                                        { printdeubg("3 compare_op\n"); }
            | NE                                        { printdeubg("4 compare_op\n"); }
            | LE                                        { printdeubg("5 compare_op\n"); }
            | GE                                        { printdeubg("6 compare_op\n"); }
            | IN                                        { printdeubg("7 compare_op\n"); }
            ;
  sign      : PLUS                                      { printdeubg("1 sign\n"); }
            | MINUS                                     { printdeubg("2 sign\n"); }
            ;
  times_op  : TIMES                                     { printdeubg("1 times_op\n"); }
            | DIVIDE                                    { printdeubg("2 times_op\n"); }
            ;
%%

/* You should add your own debugging flags below, and add debugging
   printouts to your programs.

   You will want to change DEBUG to turn off printouts once things
   are working.
  */

#define DEBUG 0

 int labelnumber = 0;  /* sequential counter for internal label numbers */

   /*  Note: you should add to the above values and insert debugging
       printouts in your routines similar to those that are shown here.     */

TOKEN cons(TOKEN item, TOKEN list) {
  printdeubg("cons()\n");
  item->link = list;
  if (DEBUG) {
    printdeubg("cons\n");
    dbugprinttok(item);
    dbugprinttok(list);
  };
  printdeubg("cons() ends\n");
  return item;
}

TOKEN unaryop(TOKEN op, TOKEN lhs) {
  printdeubg("unaryop()\n");
  op->operands = lhs;
  lhs->link = NULL;
  printdeubg("unaryop() ends\n");
  return op;
}

TOKEN binop(TOKEN op, TOKEN lhs, TOKEN rhs) { 
  printdeubg("binop()\n");
  op->operands = lhs;          /* link operands to operator       */
  lhs->link = rhs;             /* link second operand to first    */
  rhs->link = NULL;            /* terminate operand list          */
  if (DEBUG) { 
    dbugprinttok(op);
    dbugprinttok(lhs);
    dbugprinttok(rhs);
  }
  printdeubg("binop() ends\n");
  return op;
}

TOKEN findid(TOKEN tok){
  printdeubg("findid()\n");
  SYMBOL sym, typ;
  sym = searchst(tok->stringval);

  if(sym->kind != CONSTSYM){ //from project 3
    tok->symentry = sym;
    typ = sym->datatype;
    tok->symtype = typ;

    if (typ->kind == BASICTYPE || typ->kind == POINTERSYM)
      tok->datatype = typ->basicdt;
  }
  else{ //sym->kind == CONSTSYM
    tok->tokentype = NUMBERTOK;

    if(sym->basicdt ==0){           //INTEGER
      tok->datatype = INTEGER;
      tok->intval = sym->constval.intnum;
    }
    else if(sym->basicdt == 1){     //REAL
      tok->datatype = REAL;
      tok->realval = sym->constval.realnum;
    }
  }
  if (DEBUG) { 
    dbugprinttok(tok);
  }

  printdeubg("findid() ends\n");
  return tok;
}

void instvars(TOKEN id_list, TOKEN typetok) {
  printdeubg("instvars() \n");

  SYMBOL sym, typesym;
  typesym = typetok->symtype;

  int align = 0;
  //4 is alignment requirement, 16 is padding
  if(typesym->size > 4)
    align = 16;
  else
    align = alignsize(typesym);

  while (id_list != NULL) {
    sym = insertsym(id_list->stringval);
    sym->kind = VARSYM;
    sym->offset = wordaddress(blockoffs[blocknumber], align);
    sym->size = typesym->size;
    blockoffs[blocknumber] = sym->offset + sym->size;
    sym->datatype = typesym;
    sym->basicdt = typesym->basicdt;
    id_list = id_list->link;
  }
  printdeubg("instvars() ends\n");
}

void  instconst(TOKEN idtok, TOKEN consttok) {
  printdeubg("instconst()\n");

  SYMBOL sym, typesym;
  //typesym = consttok->symtype;
  
  sym = insertsym(idtok->stringval);
  sym->kind = CONSTSYM;

  //strncpy(sym->constval.stringconst, idtok->stringval, 16);

  sym->basicdt = consttok->datatype;

  //INTEGER
  if(sym->basicdt == 0){
    sym->size = 4;
    sym->constval.intnum = consttok-> intval;
  }
  //REAL
  else if(sym->basicdt == 1){  
    sym->size = 8;
    sym->constval.realnum = consttok-> realval;
  }

  if (DEBUG) { 
    dbugprinttok(idtok);
    dbugprinttok(consttok);
  }
  printdeubg("instconst() ends\n");
}

TOKEN makeif(TOKEN tok, TOKEN exp, TOKEN thenpart, TOKEN elsepart) {
  printdeubg("makeif()\n");
  tok->tokentype = OPERATOR; /* Make it look like an operator   */
  tok->whichval = IFOP;
  if (elsepart != NULL) elsepart->link = NULL;
  thenpart->link = elsepart;
  exp->link = thenpart;
  tok->operands = exp;
  if (DEBUG) {
    dbugprinttok(tok);
    dbugprinttok(exp);
    dbugprinttok(thenpart);
    dbugprinttok(elsepart);
  };
  printdeubg("makeif() ends\n");
  return tok;
}

TOKEN makeprogn(TOKEN tok, TOKEN statements) {
  printdeubg("makeprogn()\n");
  tok->tokentype = OPERATOR;
  tok->whichval = PROGNOP;
  tok->operands = statements;
  if (DEBUG) {
    printdeubg("makeprogn\n");
    dbugprinttok(tok);
    dbugprinttok(statements);
  };
  printdeubg("makeprogn() ends\n");
  return tok;
}

TOKEN makelabel() {
  printdeubg("makelabel()\n");
  TOKEN tok = talloc();
  tok->tokentype = OPERATOR;
  tok->whichval = LABELOP;
  tok->operands = makeintc(labelnumber);
  labelnumber += 1;
  printdeubg("makelabel() ends\n");
  return tok;
}

TOKEN makegoto(int label) {
  printdeubg("makegoto()\n");
  TOKEN gotoTok = talloc();
  gotoTok->tokentype = OPERATOR;
  gotoTok->whichval = GOTOOP;
  gotoTok->operands = makeintc(labelnumber - 1);
  printdeubg("makegoto() ends\n");
  return gotoTok;
}

TOKEN makefuncall(TOKEN tok, TOKEN fn, TOKEN args) {
  printdeubg("makefuncall() with args\n");
  ppexpr(args);
  tok->tokentype = OPERATOR;
  tok->whichval = FUNCALLOP;

  fn->link = args;
  tok->operands = fn;

  printdeubg("makefuncall() ends\n");
  return tok;
}

TOKEN makeintc(int num) {
  printdeubg("makeintc()\n");
  TOKEN intMade = talloc();
  intMade->tokentype = NUMBERTOK;
  intMade->datatype = INTEGER;
  intMade->intval = num;
  printdeubg("makeintc() ends\n");
  return intMade;
}

TOKEN makeprogram(TOKEN name, TOKEN args, TOKEN statements) {
  printdeubg("makeprogram()");
  if(DEBUG){
    printf(" with args:\n\t");
    ppexpr(args);
  }
  else
    printf("\n");
  TOKEN program = talloc();
  TOKEN tmpArgs = talloc();
  program->tokentype = OPERATOR;
  program->whichval = PROGRAMOP;
  program->operands = name;
  
  tmpArgs = makeprogn(tmpArgs, args);
  name->link = tmpArgs;
  tmpArgs->link = statements;
  
  printdeubg("makeprogram() ends\n");
  return program;
}

TOKEN makefor(int sign, TOKEN tok, TOKEN asg, TOKEN tokb, TOKEN endexpr, TOKEN tokc, TOKEN statement) {

  printdeubg("makefor()\n\t");

  tok->tokentype = OPERATOR;
  tok->whichval = PROGNOP;
  tok->operands = asg;

  tokb->tokentype = OPERATOR;
  tokb->whichval = LABELOP;
  asg->link=tokb;
  
  TOKEN tok1 = talloc();
  tok1->tokentype = NUMBERTOK;
  tok1->datatype = INTEGER;
  labelnumber+=1;
  tok1->intval = labelnumber; 
  
  tokb->operands = tok1;
  tokc->tokentype = OPERATOR;
  tokc->whichval = IFOP;
  tokb->link = tokc;
  
  TOKEN tok2 = talloc();
  tok2->tokentype = OPERATOR;
  tok2->whichval = LEOP;
  tokc->operands = tok2;

  TOKEN tok3 = talloc();
  tok3->tokentype = asg->operands->tokentype;
  strcpy (tok3->stringval,asg->operands->stringval);
  tok3->link = endexpr;
  tok2->operands = tok3;
  
  TOKEN tok4 = talloc();
  tok4->tokentype = OPERATOR;
  tok4->whichval = PROGNOP;
  tok2->link = tok4;
  tok4->operands = statement;

  TOKEN tok5 = talloc();
  tok5->tokentype = OPERATOR;
  tok5->whichval = ASSIGNOP;
  statement->link = tok5;

  TOKEN tok6 = talloc();
  tok6->tokentype = asg->operands->tokentype;
  strcpy (tok6->stringval,asg->operands->stringval);
  tok5->operands = tok6;
  
  TOKEN tok7 = talloc();
  tok7->tokentype = OPERATOR;
  tok7->whichval = PLUSOP;
  tok6->link = tok7;

  TOKEN tok8 = talloc();
  tok8->tokentype = asg->operands->tokentype;
  strcpy (tok8->stringval,asg->operands->stringval);
  tok7->operands = tok8;

  TOKEN tok9 = talloc();
  tok9->tokentype = NUMBERTOK;
  tok9->datatype = INTEGER;
  tok9->intval = 1;
  tok8->link = tok9;

  TOKEN tokA = talloc();
  tokA->tokentype = OPERATOR;
  tokA->whichval = GOTOOP;
  tok5->link = tokA;

  TOKEN tokB = talloc();
  tokB->tokentype = NUMBERTOK;
  tokB->datatype = INTEGER;
  tokB->intval = labelnumber;
  tokA->operands = tokB;
  
  if (DEBUG){ 
    printdeubg("makefor\n");
    dbugprinttok(tok);
    dbugprinttok(asg);
    dbugprinttok(tokb);
    dbugprinttok(endexpr);
    dbugprinttok(tokc);
    dbugprinttok(statement);
  };
  ppexpr(tok); 
  printdeubg("makefor() ends\n");
  return tok;

}

TOKEN makerepeat(TOKEN tok, TOKEN statements, TOKEN tokxzczxv, TOKEN expr) {
  printdeubg("makerepeat() \n");

  TOKEN tok1 = talloc();
  tok1->tokentype = OPERATOR;
  tok1->whichval = PROGNOP;
  
  TOKEN tok2 = talloc();
  tok2->tokentype = OPERATOR;
  tok2->whichval = LABELOP;
  
  TOKEN tok3 = talloc();    //int
  tok3->tokentype = NUMBERTOK;
  tok3->datatype = INTEGER;
  int lbl = labelnumber;
  labelnumber += 1;
  tok3->intval = lbl;
  
  tok1->operands = tok2;
  tok2->operands = tok3;
  tok2->link= statements; 
  
  printdeubg("this is what tok1 looks like after making the correction: \n");
  ppexpr(tok1);
  
  TOKEN tok4 = talloc();
  tok4->tokentype = OPERATOR;
  tok4->whichval = IFOP;
  statements->link = tok4;  
  tok4->operands = expr;
  
  TOKEN tok5 = talloc();
  tok5->tokentype = OPERATOR;
  tok5->whichval = PROGNOP;
  expr->link = tok5;
  

  TOKEN tok6 = talloc();
  tok6->tokentype = OPERATOR;
  tok6->whichval = GOTOOP;
  tok5->link = tok6;
  

  TOKEN tokr = talloc();
  tokr->tokentype = NUMBERTOK;
  tokr->datatype = INTEGER;
  tokr->intval = lbl;
  tok6->operands = tokr;

  if(DEBUG){
    printdeubg("tok1 is: \n");
    ppexpr(tok1);
  }
  printdeubg("makerepeat() ends \n");
  return tok1;
}

TOKEN findtype(TOKEN tok) {
  printdeubg("findtype() \n");

  SYMBOL sym;
  sym = searchst(tok->stringval); 
  
  if(sym->kind == TYPESYM){
    printdeubg("findtype() TYPESYM \n");
    tok->symtype = sym->datatype;
  }
  else if(sym->kind == BASICTYPE ) {
    printdeubg("findtype() BASICTYPE \n");
    tok->symtype = sym; 
    tok->datatype = sym->basicdt;    
  }
  else{
    printdeubg("findtype() found an error \n");
  }

  printdeubg("findtype() ends\n");
  return tok;
}

void printdeubg (char arr[]) {
  /*
  char array[sizeof(arr) + 1];
  int i;
  for (i=0; i < sizeof(arr); i++)
    array[i] = arr[i];
  array[sizeof(arr)] = '\0';

  if (DEBUG)
    printf("%s", arr);
  */
}
int wordaddress(int n, int wordsize) {
  return ((n + wordsize - 1) / wordsize) * wordsize;
}
yyerror(s) char * s; {
  extern int yylineno;  // defined and maintained in lex
  extern char *yytext;  // defined and maintained in lex
  fprintf(stderr, "ERROR: %s at symbol '%s' on line %d\n", s, yytext, yylineno);
  fputs(s, stderr);
  putc('\n', stderr);
}
main() {
  int res;
  initsyms();
  res = yyparse();
  printst();
  printf("yyparse result = %8d\n", res);
  if (DEBUG) 
    dbugprinttok(parseresult);
  ppexpr(parseresult); /* Pretty-print the result tree */
}