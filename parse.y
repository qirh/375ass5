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

  program   : PROGRAM IDENTIFIER LPAREN id_list RPAREN SEMICOLON lblock DOT  
                                                        { printdeubg("1 program\n"); parseresult = makeprogram($2, $4, $7); }
            ;
  variable  : IDENTIFIER                                { printdeubg("1 variable\n"); $$ = findid($1); }
            | variable DOT IDENTIFIER                   { printdeubg("2 variable\n"); $$ = reducedot($1, $2, $3); }
            | variable POINT                            { printdeubg("3 variable\n"); $$ = dopoint($1, $2); }
            | variable LBRACKET expr_list RBRACKET      { printdeubg("4 variable\n"); $$ = arrayref($1, $2, $3, $4);}
            ;
  id_list   : IDENTIFIER COMMA id_list                  { printdeubg("1 id_list\n"); $$ = cons($1, $3); }
            | IDENTIFIER                                { printdeubg("2 id_list\n"); $$ = cons($1, NULL); }
            ;  
  type      : simple_type                               { printdeubg("1 type\n"); }
            | ARRAY LBRACKET simple_type_list RBRACKET OF type { printdeubg("2 type\n"); $$ = NULL; }
            | POINT IDENTIFIER                          { printdeubg("3 type\n"); $$ = instpoint($1, $2);; }
            | RECORD field_list END                     { printdeubg("4 type\n"); $$ = makerecord($2); }      
            ;  
  label_list: num_list                                  { printdeubg("1 label_list\n"); makelabel($1); }
            ; 
  num_list  : NUMBER COMMA num_list                     { printdeubg("1 num_list\n"); $$ = cons($1, $3); }
            | NUMBER                                    { printdeubg("2 num_list\n"); }
            ; 
  fields    : id_list COLON type                        { printdeubg("1 fields\n");  }
            ;
  field_list: fields SEMICOLON field_list               { printdeubg("1 field_list\n"); $$ = nconc($1,$3); }
            | id_list COLON type                        { printdeubg("2 field_list\n"); instfields($1, $3); }
            ;
  constant  : IDENTIFIER                                { printdeubg("1 constant\n"); }
            | NUMBER                                    { printdeubg("2 constant\n"); }
            | STRING                                    { printdeubg("3 constant\n"); } 
            | sign NUMBER                               { printdeubg("4 constant\n"); }
            | sign IDENTIFIER                           { printdeubg("5 constant\n"); }
            ;
  simple_type: IDENTIFIER                               { printdeubg("1 simple_type\n"); $$ = findtype($1); }
            | LPAREN id_list RPAREN                     { printdeubg("2 simple_type ERROR\n"); $$ = NULL; }
            | NUMBER DOTDOT NUMBER                      { printdeubg("3 simple_type ERROR\n"); $$ = NULL; }
            ;
  simple_type_list : simple_type COMMA simple_type_list { printdeubg("1 simple_type_list\n"); $$ = cons($3, $1); }
                   | simple_type                        { printdeubg("2 simple_type_list\n"); }
                   ;
  block     : BEGINBEGIN statement endpart              { printdeubg("1 block\n"); $$ = makeprogn($1, cons($2, $3));  }
            ;
  cdef      : IDENTIFIER EQ constant                    { printdeubg("1 cdef\n"); instconst($1, $3); }
            ;
  cdef_list : cdef SEMICOLON cdef_list                  { printdeubg("1 cdef_list\n"); cons($1, $3); }
            | cdef SEMICOLON                            { printdeubg("2 cdef_list\n"); cons($1, NULL); }
            ;
  cblock    : CONST cdef_list tblock                    { printdeubg("1 cblock\n"); $$ = $3; }
            | tblock                                    { printdeubg("2 cblock\n"); }
            ;
  tdef      : IDENTIFIER EQ type                        { printdeubg("1 tdef\n"); maketype($1, $3); }
            ;
  tdef_list : tdef SEMICOLON tdef_list                  { printdeubg("1 tdef_list\n"); }
            | tdef                                      { printdeubg("2 tdef_list\n"); }
            ;
  tblock    : TYPE tdef_list vblock                     { printdeubg("1 tblock\n"); $$ = $3; }
            | vblock                                    { printdeubg("2 tblock\n"); }
            ;
  lblock    : LABEL label_list SEMICOLON cblock         { printdeubg("1 lblock\n"); $$ = $4; }
            | cblock                                    { printdeubg("2 lblock\n"); }
            ;
  vdef      : id_list COLON type                        { printdeubg("1 vdef\n"); instvars($1, $3); printdeubg("1 vdef end\n"); }
            ;
  vdef_list : vdef SEMICOLON vdef_list                  { printdeubg("1 vdef_list\n"); cons($1, $3); }
            | vdef                                      { printdeubg("2 vdef_list\n"); }
            | vdef SEMICOLON                            { printdeubg("3 vdef_list\n"); }
            ;
  vblock    : VAR vdef_list block                       { printdeubg("1 vblock\n"); $$ = $3; }
            | block                                     { printdeubg("2 vblock\n"); }
            ; 
  funcall   : IDENTIFIER LPAREN expr_list RPAREN        { printdeubg("1 funcall\n"); $$ = makefuncall(talloc(), $1, $3); }
            ;
  statement : BEGINBEGIN statement endpart              { printdeubg("1 statement\n"); $$ = makeprogn($1, cons($2, $3)); }
            | NUMBER COLON statement                    { printdeubg("2 statement\n"); $$ = NULL; }
            | assignment                                { printdeubg("3 statement\n"); }
            | funcall                                   { printdeubg("4 statement\n"); }
            | IF expression THEN statement endif        { printdeubg("5 statement\n"); $$ = makeif($1, $2, $4, $5); }
            | FOR assignment TO expression DO statement { printdeubg("6 statement\n"); $$ = makefor(1, $1, $2, $3, $4, $5, $6); }
            | WHILE expression DO statement             { printdeubg("7 statement\n"); $$ = makewhile($1,$2,$3,$4); }
            | REPEAT statement_list UNTIL expression    { printdeubg("8 statement\n"); $$ = makerepeat($1, $2, $3, $4); }
            | IDENTIFIER LPAREN args RPAREN             { printdeubg("9 statement\n"); $$ = makefuncall($2, $1, $3); }
            | GOTO NUMBER                               { printdeubg("A statement\n"); }
            ;
  statement_list: statement SEMICOLON statement_list    { printdeubg("1 statement_list\n"); $$ = cons($1, $3); }
            | statement                                 { printdeubg("2 statement_list\n"); }
            ;
  endpart   : SEMICOLON statement endpart               { printdeubg("1 endpart\n"); $$ = cons($2, $3); }
            | END                                       { printdeubg("2 endpart\n"); $$ = NULL; }
            ;
  endif     : ELSE statement                            { printdeubg("1 endif\n"); $$ = $2; }
            | /* empty */                               { printdeubg("2 endif\n"); $$ = NULL; }
            ;
  assignment: variable ASSIGN expression                { printdeubg("1 assignment\n"); $$ = binop($2, $1, $3); }
            ;
  expr_list : expression COMMA expr_list                { printdeubg("1 expr_list\n"); $$ = cons($1, $3); }
            | expression                                { printdeubg("2 expr_list\n"); }
            ;
  expression: expression compare_op simple_expression   { printdeubg("1 expression\n"); $$ = binop($2, $1, $3); }
            | expression sign simple_expression         { printdeubg("2 expression\n"); $$ = binop($2, $1, $3); }
            | simple_expression                         { printdeubg("3 expression\n"); }
            ;
  simple_expression: simple_expression sign term        { printdeubg("1 simple_expression\n"); $$ = binop($2, $1, $3); }
            | term                                      { printdeubg("2 simple_expression\n"); }
            | sign term                                 { printdeubg("3 simple_expression\n"); $$ = unaryop($1, $2); }
            | STRING                                    { printdeubg("4 simple_expression\n"); }
            ;
  term      : term times_op factor                      { printdeubg("1 term\n"); $$ = binop($2, $1, $3); }
            | factor                                    { printdeubg("2 term\n"); }
            ;
  factor    : LPAREN expression RPAREN                  { printdeubg("1 factor\n"); $$ = $2; }
            | MINUS variable                            { printdeubg("2 factor FUNCTION\n"); $$ = unaryop($1, $2); }
            | MINUS NUMBER                              { printdeubg("3 factor FUNCTION\n"); $$ = unaryop($1, $2); }
            | variable                                  { printdeubg("4 factor\n"); }
            | constant                                  { printdeubg("5 factor\n"); }    
            | funcall                                   { printdeubg("6 factor\n"); }   
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
  else { //sym->kind == CONSTSYM
    tok->tokentype = NUMBERTOK;

    if(sym->basicdt ==0){           //INTEGER
      tok->datatype = INTEGER;
      tok->intval = sym->constval.intnum;
    }
    else if (sym->basicdt == 1) {     //REAL
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
  if (typesym->size > 4)
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

void instconst(TOKEN idtok, TOKEN consttok) {
  printdeubg("instconst()\n");

  SYMBOL sym, typesym;
  
  sym = insertsym(idtok->stringval);
  sym->kind = CONSTSYM;

  sym->basicdt = consttok->datatype;

  //INTEGER
  if(sym->basicdt == 0){
    sym->size = 4;
    sym->constval.intnum = consttok-> intval;
  }
  //REAL
  else if (sym->basicdt == 1){  
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
    ppexpr(tok);
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
  
  tmpArgs->tokentype = OPERATOR;
  tmpArgs->whichval = PROGNOP;
  name->link = tmpArgs;

  //tmpArgs = makeprogn(tmpArgs, args);
  tmpArgs->operands = args;
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
    ppexpr(tok);
  };
   
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
  int lbl = labelnumber++;
  tok3->intval = lbl;
  
  tok1->operands = tok2;
  tok2->operands = tok3;
  tok2->link= statements; 
  if (DEBUG) {
    printdeubg("this is what tok1 looks like after making the correction: \n");
    ppexpr(tok1);
  }
  
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
  

  TOKEN tok7 = talloc();
  tok7->tokentype = NUMBERTOK;
  tok7->datatype = INTEGER;
  tok7->intval = lbl;
  tok6->operands = tok7;

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

//assignment5
TOKEN nconc(TOKEN lista, TOKEN listb){
  TOKEN tmp = lista;
  while( tmp->link )
    tmp = tmp->link;
  tmp->link = listb;
  return lista;
  
}
TOKEN makewhile(TOKEN tok, TOKEN expr, TOKEN tokb, TOKEN statement) {
  
  TOKEN labeltok = talloc();
  labeltok->tokentype = OPERATOR;
  labeltok->whichval = LABELOP;

  TOKEN numtok = talloc();
  numtok->tokentype = NUMBERTOK;
  numtok->intval = labelnumber++;
  labeltok->operands = numtok;

  TOKEN progntok = makeprogn(tok, labeltok);

  TOKEN iftok = talloc();
  iftok->tokentype = OPERATOR;
  iftok->whichval = IFOP;

  TOKEN iftest = unaryop(iftok, expr);
  
  labeltok->link = iftok;
  iftest->operands->link = statement;

  TOKEN tmp = statement->operands;
  while(tmp->link)
    tmp = tmp->link;
  
  TOKEN gototok = talloc();
  gototok->tokentype = OPERATOR;
  gototok->whichval = GOTOOP;

  TOKEN gotonum = copytoken(numtok);
  tmp->link = unaryop(gototok, gotonum);
  
  return progntok;
}
TOKEN reducedot(TOKEN var, TOKEN dot, TOKEN field) {

}
TOKEN arrayref(TOKEN arr, TOKEN tok, TOKEN subs, TOKEN tokb) {
  int index = 0;
  int offset = 0;
  SYMBOL array = arr->symtype;
  TOKEN offsetTok = NULL;
  TOKEN last = NULL;

  while(subs != NULL) {
    TOKEN link = subs->link;
    int size = array->datatype->size;

    TOKEN mul = binop(createtok(OPERATOR,TIMESOP), constant(size), subs);
    TOKEN add = binop(createtok(OPERATOR,PLUSOP), constant(-size * array->lowbound), mul);

    if(offsetTok != NULL) {
      TOKEN addlast = binop(createtok(OPERATOR,PLUSOP), offsetTok, add);
      offsetTok = addlast;
    }

    else {
      offsetTok = add;
    }
    /* Move to the next array */
    array = array->datatype;
    subs = link;
  }

  TOKEN ret = createtok(OPERATOR,AREFOP);
  array = skiptype(array);
  ret->operands = arr;
  ret->operands->link = offsetTok;
  ret->symtype = array;

  return ret;
}
SYMBOL skiptype(SYMBOL sym) {
  while(sym->kind == TYPESYM) {
    sym = sym->datatype;
  }
  return sym;
}
TOKEN dopoint(TOKEN var, TOKEN tok) {

}
TOKEN instrec(TOKEN rectok, TOKEN argstok) {

}
TOKEN instfields(TOKEN idlist, TOKEN typetok) {

}
void  insttype(TOKEN typename, TOKEN typetok) {

}

void printdeubg (char arr[]) {
  
  char array[sizeof(arr) + 1];
  int i = 0;
  for (i = 0; i < sizeof(arr); i++)
    array[i] = arr[i];
  array[sizeof(arr)] = '\0';

  if (DEBUG)
    printf("%s", arr);
  
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