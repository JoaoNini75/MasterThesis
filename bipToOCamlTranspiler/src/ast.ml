(* Abstract Syntax of BipLang *)

(* Parsed trees.
   This is the output of the parser and the input of the interpreter. *)

type location = Lexing.position * Lexing.position

type ident = { loc: location; id: string; }

type bip_type = BOOL | INT | NONE
type parameter = ident * bip_type option * bool (* floored *)

type unop =
  | Uneg    (* -e *)
  | Unot    (* not e *)
  | Uref    (* ref e *)
  | Uderef  (* !e *)

type binop =
  | Badd | Bsub | Bmul | Bdiv | Bmod    (* + - * // % *)
  | Beq | Bneq | Blt | Ble | Bgt | Bge  (* == != < <= > >= *)
  | Band | Bor | Bspeq                  (* and or <-> *)

type constant =
  | Cnone
  | Cint of     int
  | Cbool of    bool
  | Cstring of  string

type expr =
  | Eident of   ident
  | Ecst of     constant
  | Eunop of    unop * expr
  | Ebinop of   binop * expr * expr
  | Slet of     ident * expr * expr
  | Sfun of     def
  | Sapp of     ident * expr list
  | Sif of      expr * expr list * expr list
  | Sfor of     ident * expr * expr * expr list  
  | Swhile of   expr * expr list 
  | Sset of     ident * expr (* x := 3 *)
  | Sfloor of   expr (* |_ expr _| *)
  | Spipe of    expr * expr (* expr | expr *)
  | Sflrlet of  ident * expr (* |_ let x = 2 in _| *)
  | Spipelet of ident * expr * ident * expr (* let x = 2 in | let x = 3 in *)

and def = ident * parameter list * bip_type option * bool (* floored *) * expr list

and file = def list
   