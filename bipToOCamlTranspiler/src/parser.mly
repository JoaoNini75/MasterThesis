
/* Parser for BipLang */

%{
  open Ast
%}

%token <Ast.constant> CST
%token <Ast.binop> CMP
%token <string> IDENT
%token LET IN REF IF THEN ELSE PRINT FOR WHILE TO DO DONE NOT INT BOOL AND OR SET DEREF PIPE LFLOOR RFLOOR SPEC_EQUAL
%token EOF
%token LP RP LSQ RSQ COMMA EQUAL COLON SEMICOLON BEGIN END NEWLINE
%token PLUS MINUS TIMES DIV MOD

/* priorities and associativities */

%left OR
%left AND
%nonassoc NOT
%nonassoc CMP
%left PLUS MINUS
%left TIMES DIV MOD
%nonassoc unary_minus
%nonassoc LSQ

%start file
%type <Ast.file> file

%%

file:
| NEWLINE? dl = list(def) b = nonempty_list(stmt) NEWLINE? EOF
    { dl, Sblock b }
;

def:
| LET f = ident LP x = separated_list(COMMA, ident) RP
  COLON s = suite
    { f, x, s }
;

expr:
| c = CST
    { Ecst c }
| id = ident
    { Eident id }
(* | e1 = expr LSQ e2 = expr RSQ
    { Eget (e1, e2) } *)
| MINUS e1 = expr %prec unary_minus
    { Eunop (Uneg, e1) }
| NOT e1 = expr
    { Eunop (Unot, e1) }
| REF e1 = expr
    { Eunop (Uref, e1) } 
| DEREF e1 = expr
    { Eunop (Uderef, e1) } 
| e1 = expr op = binop e2 = expr
    { Ebinop (op, e1, e2) }
(* | f = ident LP e = separated_list(COMMA, expr) RP
    { Ecall (f, e) }
| LSQ l = separated_list(COMMA, expr) RSQ
    { Elist l } *)
| LP e = expr RP
    { e }
;

suite:
| s = simple_stmt NEWLINE
    { s }
(*| NEWLINE BEGIN l = nonempty_list(stmt) END
    { Sblock l } *)
;

stmt:
| s = simple_stmt NEWLINE
    { s }
| IF c = expr THEN s = suite
    { Sif (c, s) }
| IF c = expr THEN s1 = suite ELSE s2 = suite
    { Sifelse (c, s1, s2) }
| FOR id = ident EQUAL e1 = expr TO e2 = expr DO s = suite DONE SEMICOLON
    { Sfor (id, e1, e2, s) }
| WHILE e = expr DO s = suite DONE SEMICOLON
    { Swhile (e, s) }   
| LET id = ident EQUAL e = expr IN
    { Slet (id, e) }
| id = ident EQUAL e = expr IN
    { Sassign (id, e) }
| id = ident SET e = expr
    { Sset (id, e) }    
| LFLOOR s = suite RFLOOR
    { Sfloor (s) }
| s1 = suite PIPE s2 = suite
    { Spipe (s1, s2) }
;

simple_stmt:
(* | id = ident EQUAL e = expr
    { Sassign (id, e) } 
| e1 = expr LSQ e2 = expr RSQ EQUAL e3 = expr
    { Sset (e1, e2, e3) } *)
| PRINT LP e = expr RP
    { Sprint e }
(* | e = expr
    { Seval e } *)
;

%inline binop:
| PLUS  { Badd }
| MINUS { Bsub }
| TIMES { Bmul }
| DIV   { Bdiv }
| MOD   { Bmod }
| c=CMP { c    }
| AND   { Band }
| OR    { Bor  }
;

ident:
  id = IDENT { { loc = ($startpos, $endpos); id } }
;


