(* Abstract Syntax of BipLang *)

(* Parsed trees.
   This is the output of the parser and the input of the interpreter. *)

type location = Lexing.position * Lexing.position

type ident = { loc: location; id: string; }

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
  | Slet of     ident * expr
  | Sfun of     ident * ident list * expr
  | Sapp of     ident * expr list
  | Sifelse of  expr * expr * expr
  | Sfor of     ident * expr * expr * expr (* list? *)
  | Swhile of   expr * expr (* list? *)
  | Sassign of  ident * expr
  | Sset of     ident * expr
  | Sprint of   expr
  | Sfloor of   expr (* |_ expr _| *)
  | Spipe of    expr * expr (* expr | expr *)

and def = ident * ident list * expr

and file = def list
   