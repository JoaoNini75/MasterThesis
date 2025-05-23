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
  | Elet of     ident * expr * expr
  | Efun of     def
  | Eapp of     ident * expr list
  | Eif of      expr * expr list * expr list
  | Efor of     ident * expr * expr * expr list  
  | Ewhile of   expr * expr list 
  | Eassign of  ident * expr (* x := 3 *)
  | Efloor of   expr (* |_ expr _| *)
  | Epipe of    expr * expr (* expr | expr *)
  | Eflrlet of  ident * expr (* |_ let x = 2 in _| *)
  | Epipelet of ident * expr * ident * expr (* let x = 2 in | let x = 3 in *)

and def = ident * parameter list * bip_type option * bool (* floored *) * expr list

and file = def list
   