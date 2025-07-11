
/* Parser for BipLang */

%{
  open Ast_core
  open Ast_bip
%}

%token <Ast_core.constant> CST
%token <Ast_core.binop> CMP
%token <string> IDENT
%token <string> SPEC
%token LET REC ASSERT MATCH WITH ARROW WILDCARD IN REF IF THEN ELSE FOR WHILE TO DO DONE NOT INT BOOL STRING LOGICAND LOGICOR NONE ASSIGN DEREF PIPE LFLOOR RFLOOR SPEC_EQUAL
%token EOF
%token LP RP LSQ RSQ COMMA EQUAL COLON SEMICOLON DOT BEGIN END
%token PLUS MINUS TIMES DIV MOD

/* priorities and associativities */
%nonassoc MATCH WITH
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
| dl = list(decl) EOF
    { dl }
;

decl:
| sp = spec
    { Espec sp }
| is_rec = fun_rec f = ident LP x = separated_list(COMMA, parameter) RP fr = fun_ret? EQUAL b = block sp = spec
    { 
      match fr with
      | None -> Edef (f, is_rec, x, None, None, b, sp)
      | Some (tp, spop) -> Edef (f, is_rec, x, Some tp, spop, b, sp)
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
| LET id1 = ident EQUAL value1 = expr PIPE id2 = ident EQUAL value2 = expr IN body = expr
    { Eletpipe (id1, value1, id2, value2, body) } 
| IF c = expr THEN s1 = block ELSE s2 = block
    { Eif (c, s1, s2) }
| FOR id = ident EQUAL value = expr TO e_to = expr DO sp = spec? body = block_core DONE 
    { Efor (id, value, e_to, sp, body) }
| WHILE cnd = expr DO sp = spec? body = block_core DONE 
    { Ewhile (cnd, sp, body) }
| WHILE cnd1 = expr PIPE cnd2 = expr DOT ag1 = expr PIPE ag2 = expr DO sp = spec? body = block_core DONE
    { Ewhilecnd (cnd1, cnd2, ag1, ag2, sp, body) }
| id = ident ASSIGN e = expr
    { Eassign (id, e) }
| LFLOOR e = expr RFLOOR
    { Efloor (e) }
| e1 = expr PIPE e2 = expr
    { Epipe (e1, e2) }
| id = ident LP args = separated_list(COMMA, expr) RP
    { Eapp (id, args) }
| ASSERT LP e = expr RP
    { Eassert (e) }
| LP MATCH id = ident WITH PIPE cases = separated_list(PIPE, case) RP
    { Ematch (id, cases) }
| LP e = expr RP
    { e }
;

case:
| LP ptrn = pattern ARROW e = expr RP
    { (ptrn, e) }
;

parameter_core:
| id = ident COLON? tp = bip_type?
    { id, tp }
;

parameter:
| pc = parameter_core
    { let (id, tp) = pc in (id, tp, None) }
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

fun_rec:
| LET REC { true }
| LET { false }
;

pattern:
| WILDCARD   { Pwildcard }
| c = CST    { Pconst (c) }
| id = ident { Pident (id) }
;

bip_type:
| INT       { INT }
| BOOL      { BOOL }
| STRING    { STRING }
| NONE      { NONE }
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

spec:
  text = SPEC { { loc = ($startpos, $endpos); text } }
;
