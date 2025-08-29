
/* Parser for BipLang */

%{
  open Ast_core
  open Ast_bip
%}

%token <Ast_core.constant> CST
%token <Ast_core.binop> CMP
%token <string> IDENT
%token <string> SPEC
%token <string> IDENT_CAP
%token CASE
%token LET REC ASSERT MATCH WITH ARROW WILDCARD IN REF IF THEN ELSE FOR WHILE TO DO DONE NOT INT BOOL STRING UNIT LOGICAND LOGICOR NONE ASSIGN DEREF PIPE LFLOOR RFLOOR TYPE OF AND OPEN INCLUDE LSQBR RSQBR INVARROW
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
%nonassoc TUPLE_REDUCE
%nonassoc IDENT_REDUCE
%left PLUS MINUS
%left TIMES DIV MOD
%nonassoc CASE
%nonassoc unary_minus
%nonassoc REF DEREF
%right DOT


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
| td = type_def
    { Etypedef td }
| OPEN m = ident_cap
    { Eopen m }
| INCLUDE m = ident_cap
    { Einclude m }
;

type_def:
| TYPE tdc = type_def_core
    { tdc }
;

and_type_def:
| AND tdc = type_def_core
    { tdc }
;

type_def_core:
| name = ident EQUAL pl = payload atd = and_type_def?
    { TDsimple (name, pl, atd) }
| name = ident EQUAL CASE cons = separated_nonempty_list(CASE, constructor) atd = and_type_def?
    { TDcons (name, cons, atd) }
;

def_outer:
| LET REC f = ident x = param_list fr = fun_ret? EQUAL body = block sp = spec
    { (f, true, x, fr, body, sp) }
| LET     f = ident x = param_list fr = fun_ret? EQUAL body = block sp = spec
    { (f, false, x, fr, body, sp) }
;

def_inner:
| LET REC f = ident x = param_list fr = fun_ret? EQUAL body = block sp = spec IN after = expr
    { Efun (f, true, x, fr, body, sp, after) }
| LET     f = ident x = param_list fr = fun_ret? EQUAL body = block sp = spec IN after = expr
    { Efun (f, false, x, fr, body, sp, after) }
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
| id = ident %prec IDENT_REDUCE
    { Eident id }
| tpt = two_plus_tuple
    { Etuple tpt }
| cn = ident_cap t = tuple 
    { Econs (cn, t) }
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
| ic = ident_cap DOT id = ident args = app_body 
    { Emodapp (ic, id, args) } 
| ASSERT LP e = expr RP
    { Eassert (e) }
| MATCH id = ident WITH cases = case_list
    { Ematch (id, cases) }
| LSQBR CASE array = separated_list(SEMICOLON, expr) CASE RSQBR
    { Earray_new array }
| id = ident DOT LP e = expr RP
    { Earray_read (id, e) }
| id = ident DOT LP e1 = expr RP INVARROW e2 = expr %prec IDENT_REDUCE
    { Earray_write (id, e1, e2) }
| efun = def_inner
    { efun }
| LP e = expr RP
    { e }
;

tuple: (* expressions are not allowed in unary tuples for now *)
| %prec TUPLE_REDUCE
    { [] }
| id = ident
    { [Eident id] }
| LP id = ident RP
    { [Eident id] }
| tpt = two_plus_tuple
    { tpt }
;

two_plus_tuple: (* tuple with arity >= 2 *)
| LP first = expr COMMA rest = separated_list(COMMA, expr) RP
    { first :: rest }
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
| COLON rt = ret_type
    { (rt, None) }
| COLON LFLOOR rt = ret_type RFLOOR
    { (rt, Some SOfloor) }
| COLON rt1 = ret_type PIPE rt2 = ret_type
    { (rt1, Some SOpipe) }
;

ret_type:
| bt = bip_type 
    { Some (Retbt (bt)) }
| id = ident
    { Some (Retcn (id)) }
;

constructor:
| cn = ident_cap OF pl = payload
    { cn, Some pl }
| cn = ident_cap
    { cn, None }    
;

payload:
| pl = separated_nonempty_list(TIMES, payload_elem)
    { pl }
;

payload_elem:
| bt = bip_type
    { PLexisting bt }
| id = ident
    { PLnew id }
;

pattern:
| WILDCARD      { Ewildcard }
| c = CST       { Econst c }
| id = ident    { Eident id }
| cn = ident_cap t = tuple
    { Econstructor (cn, t) } 
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

ident_cap:
  cn = IDENT_CAP { cn }
;
