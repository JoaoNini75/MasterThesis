
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
%left SEMICOLON
%left PRINT
%nonassoc ELSE 
%nonassoc SET
%nonassoc IN
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
| LET f = ident LP x = separated_list(COMMA, ident) RP (*(COLON t = (INT | BOOL))?*) EQUAL s = expr 
    { f, x, s }
;

expr:
| LP e = expr RP
    { Seval (e) }
| BEGIN e = expr END
    { Seval (e) }
| e1 = expr SEMICOLON e2 = expr
    { Sseq (e1, e2) }
(*| e1 = expr SEMICOLON PIPE e2 = expr SEMICOLON
    { Sseq (e1, e2) } *)
| c = CST
    { Ecst c }
| id = ident
    { Eident id }
| LET id = ident EQUAL e1 = expr IN e2 = expr
    { Slet (id, e1, e2) } 
| MINUS e1 = expr %prec unary_minus
    { Eunop (Uneg, e1) }
| NOT e1 = expr
    { Eunop (Unot, e1) }
| REF e1 = expr
    { Eunop (Uref, e1) } 
| DEREF e1 = expr
    { Eunop (Uderef, e1) }
| id = ident SET e = expr
    { Sset (id, e) } 
| e1 = expr op = binop e2 = expr
    { Ebinop (op, e1, e2) }
| IF c = expr THEN s1 = expr ELSE s2 = expr
    { Sifelse (c, s1, s2) }
| FOR id = ident EQUAL value = expr TO e_to = expr DO body = expr DONE SEMICOLON after = expr
    { Sfor (id, value, e_to, body, after) }
| WHILE cnd = expr DO body = expr DONE SEMICOLON after = expr
    { Swhile (cnd, body, after) }     
| LFLOOR s = expr RFLOOR
    { Sfloor (s) }
| e1 = expr PIPE e2 = expr SEMICOLON after = expr
    { Spipe (e1, e2, after) }
(* | PRINT e = expr
    { Sprint e } *)
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
