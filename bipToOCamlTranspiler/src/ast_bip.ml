(* Abstract Syntax of BipLang *)

(* Parsed trees.
   This is the output of the parser and the input of the interpreter. *)
   
open Ast_core

type pattern = 
  | Ewildcard
  | Econst of       constant
  | Eident of       ident
  | Econstructor of ident_cap * expr list
(* only allowing some patterns for now *)

and case = pattern * expr 

and expr =
  | Eunit 
  | Eident of     ident
  | Etuple of     expr list
  | Econs of      ident_cap * expr list
  | Ecst of       constant
  | Eunop of      unop * expr
  | Ebinop of     binop * expr * expr
  | Elet of       ident * expr * expr
  | Eletpipe of   ident * expr * ident * expr * expr
  | Efun of       ident * bool (* rec *) * parameter list * fun_ret * expr list * spec * expr
  | Eapp of       ident * expr list
  | Eif of        expr * expr list * expr list
  | Efor of       ident * expr * expr * spec option * expr list  
  | Ewhile of     expr * spec option * expr list 
  | Ewhilecnd of  expr * expr * expr * expr * spec option * expr list 
  | Eassign of    ident * expr (* x := 3 *)
  | Eassert of    expr
  | Ematch of     ident * case list
  | Efloor of     expr (* |_ expr _| *)
  | Epipe of      expr * expr (* expr | expr *)

and def = ident * bool (* rec *) * parameter list * fun_ret * expr list * spec

and decl = 
  | Edef of     def
  | Espec of    spec
  | Etypedef of typedef
  | Eopen of    ident_cap
  | Einclude of ident_cap
  
and file = decl list
   