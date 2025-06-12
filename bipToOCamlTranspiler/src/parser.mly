
/* Parser for BipLang */

%{
  open Ast_core
  open Ast_bip
%}

%token <Ast_core.constant> CST
%token <Ast_core.binop> CMP
%token <string> IDENT
%token <string> COMMENT
%token LET IN REF IF THEN ELSE FOR WHILE TO DO DONE NOT INT BOOL LOGICAND LOGICOR NONE ASSIGN DEREF PIPE LFLOOR RFLOOR SPEC_EQUAL
%token EOF
%token LP RP LSQ RSQ COMMA EQUAL COLON SEMICOLON BEGIN END
%token PLUS MINUS TIMES DIV MOD

/* priorities and associativities */

%nonassoc IN
%left PIPE
%nonassoc ASSIGN
%left LOGICOR LOGICAND
%nonassoc NOT
%nonassoc CMP
%left PLUS MINUS
%left TIMES DIV MOD
%nonassoc unary_minus
%nonassoc REF DEREF


%start file
%type <Ast_bip.file> file

%%

file:
| dl = list(def) EOF
    { dl }
;

def:
| LET f = ident LP x = separated_list(COMMA, parameter) RP fr = fun_ret? EQUAL b = block 
    { 
      match fr with
      | None -> (f, x, None, None, b)
      | Some (tp, spop) -> (f, x, Some tp, spop, b)
    }
;

block:
| BEGIN b = block_core END
    { b }
;

block_core:
| e = expr
    { [e] }
| e = expr SEMICOLON b = block_core 
    { e :: b }
;

expr:
| c = comment 
    { Ecomment c }
| LP e = expr RP
    { e }
| c = CST
    { Ecst c }
| id = ident
    { Eident id }  
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
| LET id = ident EQUAL value = expr IN body = expr
    { Elet (id, value, body) } 
| LET id = ident EQUAL LFLOOR value = expr RFLOOR IN body = expr
    { Elet (id, Efloor value, body) } 
| LET id = ident EQUAL LP value1 = expr PIPE value2 = expr RP IN body = expr
    { Elet (id, Epipe (value1, value2), body) }   
| IF c = expr THEN s1 = block ELSE s2 = block
    { Eif (c, s1, s2) }
| IF LFLOOR c = expr RFLOOR THEN s1 = block ELSE s2 = block
    { Eif (Efloor c, s1, s2) }
| IF c1 = expr PIPE c2 = expr THEN s1 = block ELSE s2 = block
    { Eif (Epipe (c1, c2), s1, s2) }
| FOR id = ident EQUAL value = expr TO e_to = expr DO body = block_core DONE 
    { Efor (id, value, e_to, body) }
| WHILE cnd = expr DO body = block_core DONE 
    { Ewhile (cnd, body) }
| WHILE LP LFLOOR cnd = expr RFLOOR RP DO body = block_core DONE 
    { Ewhile (Efloor cnd, body) }
| WHILE LP c1 = expr PIPE c2 = expr RP DO body = block_core DONE 
    { Ewhile (Epipe (c1, c2), body) }    
| id = ident ASSIGN e = expr
    { Eassign (id, e) }
| id = ident ASSIGN LP e = expr RFLOOR
    { Eassign (id, Efloor e) }
| id = ident ASSIGN LP e1 = expr PIPE e2 = expr RP
    { Eassign (id, Epipe (e1, e2)) }          
| LFLOOR e = expr RFLOOR
    { Efloor (e) }
| e1 = expr PIPE e2 = expr
    { Epipe (e1, e2) }
| id = ident LP args = separated_list(COMMA, expr) RP
    { Eapp (id, args) }
;

parameter_core:
| id = ident COLON? tp = bip_type?
    { id, tp }
;

parameter:
| pc = parameter_core
    { let (id, tp) = pc in(id, tp, None) }
| LFLOOR pc = parameter_core RFLOOR
    { let (id, tp) = pc in (id, tp, Some SOfloor) }
| pc1 = parameter_core PIPE pc2 = parameter_core
    { let (id, tp) = pc1 in (id, tp, Some SOpipe) }
;

fun_ret:
| COLON tp = bip_type
    { tp, None }
| COLON LFLOOR tp = bip_type RFLOOR
    { tp, Some SOfloor }
| COLON tp1 = bip_type PIPE tp2 = bip_type
    { tp1, Some SOpipe }
;

bip_type:
| INT  { INT }
| BOOL { BOOL }
| NONE { NONE }
;

%inline binop:
| PLUS      { Badd }
| MINUS     { Bsub }
| TIMES     { Bmul }
| DIV       { Bdiv }
| MOD       { Bmod }
| c=CMP     { c    }
| LOGICAND  { Band }
| LOGICOR   { Bor  }
;

ident:
  id = IDENT { { loc = ($startpos, $endpos); id } }
;

comment:
  text = COMMENT { { loc = ($startpos, $endpos); text } }
;
