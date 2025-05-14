
/* Parser for BipLang */

%{
  open Ast
%}

%token <Ast.constant> CST
%token <Ast.binop> CMP
%token <string> IDENT
%token LET IN REF IF THEN ELSE PRINT FOR WHILE TO DO DONE NOT INT BOOL AND OR SET DEREF PIPE LFLOOR RFLOOR SPEC_EQUAL
%token EOF
%token LP RP LSQ RSQ COMMA EQUAL COLON SEMICOLON BEGIN END
%token PLUS MINUS TIMES DIV MOD

/* priorities and associativities */

%left PIPE
%left PRINT
%nonassoc ELSE 
%nonassoc SET
%left OR
%left AND
%nonassoc NOT
%nonassoc CMP
%left PLUS MINUS
%left TIMES DIV MOD
%nonassoc unary_minus
%nonassoc REF DEREF

%start file

%type <Ast.file> file

%%

file:
| dl = list(def) EOF
    { dl }
;

def:    (* let id (x, y, z) = body *)
| LET f = ident LP x = separated_list(COMMA, ident) RP EQUAL s = expr
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
| IF c = expr THEN s1 = expr ELSE s2 = expr
    { Sifelse (c, s1, s2) }
| FOR id = ident EQUAL e1 = expr TO e2 = expr DO s = expr DONE SEMICOLON
    { Sfor (id, e1, e2, s) }
| WHILE e = expr DO s = expr DONE SEMICOLON
    { Swhile (e, s) }   
| LET id = ident EQUAL e = expr IN
    { Slet (id, e) }
| id = ident EQUAL e = expr IN
    { Sassign (id, e) }
| id = ident SET e = expr
    { Sset (id, e) }    
| LFLOOR s = expr RFLOOR
    { Sfloor (s) }
| s1 = expr PIPE s2 = expr
    { Spipe (s1, s2) }
| PRINT e = expr
    { Sprint e }
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
