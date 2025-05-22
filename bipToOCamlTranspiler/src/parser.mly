
/* Parser for BipLang */

%{
  open Ast
%}

%token <Ast.constant> CST
%token <Ast.binop> CMP
%token <string> IDENT
%token LET IN REF IF THEN ELSE FOR WHILE TO DO DONE NOT INT BOOL NONE AND OR SET DEREF PIPE LFLOOR RFLOOR SPEC_EQUAL
%token EOF
%token LP RP LSQ RSQ COMMA EQUAL COLON SEMICOLON BEGIN END
%token PLUS MINUS TIMES DIV MOD

/* priorities and associativities */

%nonassoc IN
%left PIPE
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

def:
| LET f = ident LP x = separated_list(COMMA, parameter) RP fr = fun_ret? EQUAL b = block 
    { 
      match fr with
      | None -> (f, x, None, false, b)
      | Some (tp, flrd) -> (f, x, Some tp, flrd, b)
    }
;

block:
| BEGIN b = block_core END
    { b }

block_core:
| e = expr
    { [e] }
| e = expr SEMICOLON b = block_core 
    { e :: b }

expr:
| LP e = expr RP
    { e }
| c = CST
    { Ecst c }
| id = ident
    { Eident id }
| LET id = ident EQUAL value = expr IN body = expr
    { Slet (id, value, body) } 
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
| IF c = expr THEN s1 = block ELSE s2 = block
    { Sif (c, s1, s2) }
| FOR id = ident EQUAL value = expr TO e_to = expr DO body = block_core DONE 
    { Sfor (id, value, e_to, body) }
| WHILE cnd = expr DO body = block_core DONE 
    { Swhile (cnd, body) }     
| LFLOOR s = expr RFLOOR
    { Sfloor (s) }
| e1 = expr PIPE e2 = expr
    { Spipe (e1, e2) }
| LFLOOR ls = let_short RFLOOR
    { let (id, value) = ls in
      Sflrlet (id, value) }
| ls1 = let_short PIPE ls2 = let_short
    { let (id1, value1) = ls1 in 
      let (id2, value2) = ls2 in 
      Spipelet (id1, value1, id2, value2) }
;

let_short:
| LET id = ident EQUAL value = expr IN
    { (id, value) }
;

parameter_core:
| id = ident COLON? tp = bip_type?
    { id, tp, false }
;

parameter:
| pc = parameter_core
| LFLOOR pc = parameter_core RFLOOR
    { let (id, tp, _) = pc in (id, tp, true) }
;

fun_ret:
| COLON tp = bip_type
    { tp, false }
| COLON LFLOOR tp = bip_type RFLOOR
    { tp, true }
;

bip_type:
| INT { INT }
| BOOL { BOOL }
| NONE { NONE }
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
