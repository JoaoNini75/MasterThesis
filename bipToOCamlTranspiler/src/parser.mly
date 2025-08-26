
/* Parser for BipLang */

%{
  open Ast_core
  open Ast_bip
%}

%token <Ast_core.constant> CST
%token <Ast_core.binop> CMP
%token <string> IDENT
%token <string> SPEC
%token CASE
%token LET REC ASSERT MATCH WITH ARROW WILDCARD IN REF IF THEN ELSE FOR WHILE TO DO DONE NOT INT BOOL STRING UNIT LOGICAND LOGICOR NONE ASSIGN DEREF PIPE LFLOOR RFLOOR TYPE OF
%token EOF
%token LP RP COMMA EQUAL COLON SEMICOLON DOT BEGIN END
%token PLUS MINUS TIMES DIV MOD

/* priorities and associativities */
%nonassoc ARROW
%nonassoc WITH
%nonassoc IN
%left PIPE
%nonassoc ASSIGN
%left LOGICOR LOGICAND
%nonassoc NOT
%nonassoc CMP
%left PLUS MINUS
%left TIMES DIV MOD
%nonassoc CASE
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
| edef = def_outer
    { Edef edef }
| sp = spec
    { Espec sp }
| TYPE typename = ident EQUAL pl = payload
    { Etypedef (TDsimple(typename, pl)) }    
| TYPE typename = ident EQUAL CASE constructors = separated_nonempty_list(CASE, constructor)
    { Etypedef (TDcons(typename, constructors)) }
;

def_outer:
| LET REC f = ident x = param_list fr = fun_ret? EQUAL b = block sp = spec
    { match fr with
      | None -> (f, true, x, None, None, b, sp)
      | Some (tp, spop) -> (f, true, x, Some tp, spop, b, sp) }
| LET     f = ident x = param_list fr = fun_ret? EQUAL b = block sp = spec
    { match fr with
      | None -> (f, false, x, None, None, b, sp)
      | Some (tp, spop) -> (f, false, x, Some tp, spop, b, sp) }
;

def_inner:
| LET REC f = ident x = param_list fr = fun_ret? EQUAL body = block sp = spec IN after = expr
    { match fr with
      | None -> Efun (f, true, x, None, None, body, sp, after)
      | Some (tp, spop) -> Efun (f, true, x, Some tp, spop, body, sp, after) }
| LET     f = ident x = param_list fr = fun_ret? EQUAL body = block sp = spec IN after = expr
    { match fr with
      | None -> Efun (f, false, x, None, None, body, sp, after)
      | Some (tp, spop) -> Efun (f, false, x, Some tp, spop, body, sp, after) }
;

param_list:
| UNIT
    { [Punit] }
| LP params = separated_list(COMMA, parameter) RP
    { params }
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
| UNIT 
    { Eunit }
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
| id = ident args = app_body 
    { Eapp (id, args) }
| ASSERT LP e = expr RP
    { Eassert (e) }
| MATCH id = ident WITH cases = case_list
    { Ematch (id, cases) }
| efun = def_inner
    { efun }
| LP e = expr RP
    { e }
;

app_body:
| UNIT
    { [Eunit] }
| LP args = separated_list(COMMA, expr) RP
    { args }
;

case_list:
| c = case
    { [c] }
| cl = case_list c = case
    { c :: cl }
;

case:
| CASE ptrn = pattern ARROW e = expr %prec ARROW
    { (ptrn, e) }
;

parameter_core:
| id = ident COLON? tp = bip_type?
    { id, tp }
;

parameter:
| pc = parameter_core
    { let (id, tp) = pc in Param (id, tp, None) }
| LFLOOR pc = parameter_core RFLOOR
    { let (id, tp) = pc in Param (id, tp, Some SOfloor) }
| pc1 = parameter_core PIPE pc2 = parameter_core
    { let (id, tp) = pc1 in Param (id, tp, Some SOpipe) }
;

fun_ret:
| COLON tp = bip_type
    { tp, None }
| COLON LFLOOR tp = bip_type RFLOOR
    { tp, Some SOfloor }
| COLON tp1 = bip_type PIPE tp2 = bip_type
    { tp1, Some SOpipe }
;

constructor:
| cons_name = ident OF pl = payload
    { cons_name, Some pl }
| cons_name = ident
    { cons_name, None }    
;

payload:
| pl = separated_nonempty_list(TIMES, payload_elem)
    { pl }
;

payload_elem:
| plel = bip_type
    { PLexisting plel }
| plel = ident
    { PLnew plel }
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
