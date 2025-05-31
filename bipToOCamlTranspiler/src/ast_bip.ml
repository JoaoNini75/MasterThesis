(* Abstract Syntax of BipLang *)

(* Parsed trees.
   This is the output of the parser and the input of the interpreter. *)
   
open Ast_core

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

and def = ident * parameter list * bip_type option
          * special_op option * expr list

and file = def list
   