(* Abstract Syntax of (simplified) OCaml *)

(* Parsed trees.
   This is the output of the parser and the input of the interpreter. *)

open Ast_core

type oexpr =
  | Onone
  | Ounit
  | Oident of   ident
  | Ocst of     constant
  | Ounop of    unop * oexpr
  | Obinop of   binop * oexpr * oexpr
  | Olet of     ident * oexpr * oexpr
  | Ofun of     ident * bool (* rec *) * parameter list * bip_type option
                * bool (* return pair *) * oexpr list * spec * oexpr
  | Oapp of     ident * oexpr list
  | Oif of      oexpr * oexpr * oexpr list * oexpr list
  | Ofor of     ident * oexpr * oexpr * spec option * oexpr list  
  | Owhile of   oexpr * oexpr * spec option * oexpr list
  | Oassign of  ident * ident * oexpr * oexpr (* x := 3 *)
  | Oassert of  oexpr
  | Omatch of   ident * ocase list
  | Oseq of     oexpr * oexpr

and ocase = pattern * oexpr 

and odef = ident * bool (* rec *) * parameter list * bip_type option
           * bool (* return pair *) * oexpr list * spec

and odecl = 
  | Odef of   odef
  | Ospec of  spec
  
and ofile = odecl list
   