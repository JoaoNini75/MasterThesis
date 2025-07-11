(* Abstract Syntax of BipLang *)

(* Parsed trees.
   This is the output of the parser and the input of the interpreter. *)
   
open Ast_core

type expr =
  | Eident of     ident
  | Ecst of       constant
  | Eunop of      unop * expr
  | Ebinop of     binop * expr * expr
  | Elet of       ident * expr * expr
  | Eletpipe of   ident * expr * ident * expr * expr
  | Efun of       def
  | Eapp of       ident * expr list
  | Eif of        expr * expr list * expr list
  | Efor of       ident * expr * expr * spec option * expr list  
  | Ewhile of     expr * spec option * expr list 
  | Ewhilecnd of  expr * expr * expr * expr * spec option * expr list 
  | Eassign of    ident * expr (* x := 3 *)
  | Eassert of    expr
  | Efloor of     expr (* |_ expr _| *)
  | Epipe of      expr * expr (* expr | expr *)

and def = ident * bool (* rec *) * parameter list * bip_type option
          * special_op option * expr list * spec

and decl = 
  | Edef of   def
  | Espec of  spec
  
and file = decl list
   