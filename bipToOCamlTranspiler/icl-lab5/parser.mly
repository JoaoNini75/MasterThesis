
/* Syntactic analyzer for mini-Turtle */

%{
  open Ast

%}

/* Tokens declaration */

%token EOF
/* TODO */

/* Tokens priorities and associativity */
/* TODO */

/* Grammar entry-point */
%start prog

/* Type of returned values for the syntactic analyzer */
%type <Ast.program> prog

%%

/* Grammar rules */

prog:
  /* TODO */ EOF
    { { defs = []; main = Sblock [] } (* TO CHANGE *) }
;
