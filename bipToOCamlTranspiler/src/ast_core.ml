(* Common Abstract Syntax between BipLang and OCaml *)

(* Parsed trees.
   This is the output of the parser and the input of the interpreter. *)

type location = Lexing.position * Lexing.position

type ident = { loc: location; id: string; }
type spec = { loc: location; text: string; } (* Gospel specifications *)
type ident_cap = string

type bip_type = BOOL | INT | STRING | NONE
type special_op = SOfloor | SOpipe  
type any_type = 
  | ATbt of bip_type
  | ATid of ident

type ret_type = 
  | Retbt of bip_type * ident option
  | Retcn of ident * ident option

type fun_ret = (ret_type option * special_op option) option

type parameter = 
  | Punit
  | Param of ident * any_type option * special_op option * ident option (* array, list, etc *)

type unop =
  | Uneg    (* -e *)
  | Unot    (* not e *)
  | Uref    (* ref e *)
  | Uderef  (* !e *)

type binop =
  | Badd | Bsub | Bmul | Bdiv | Bmod    (* + - * // % *)
  | Beq | Bneq | Blt | Ble | Bgt | Bge  (* = <> < <= > >= *)
  | Band | Bor | Beqphy | Bneqphy       (* && || <-> == != *)

type constant =
  | Cnone
  | Cint of     int
  | Cbool of    bool
  | Cstring of  string

type payload_elem =
  | PLexisting of bip_type
  | PLnew of      ident

type payload = payload_elem list

type constructor = ident_cap * payload option

type typedef = 
  (* type ex1 = int * string *)
  | TDsimple of ident * payload * typedef option
  (* type ex2 = | Cons1 | Cons2 of bool *)
  | TDcons of   ident * constructor list * typedef option 

type array_ptrn =
  | APid of   ident
  | APcst of  constant
  | APwc

type prepend_elem =
  | PPDid of    ident
  | PPDcst of   constant
  | PPDrec of   prepend_elem * prepend_elem option
