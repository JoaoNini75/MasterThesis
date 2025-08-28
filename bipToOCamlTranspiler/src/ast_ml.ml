(* Abstract Syntax of (simplified) OCaml *)

(* Parsed trees.
   This is the output of the parser and the input of the interpreter. *)

open Ast_core

type opattern = 
  | Owildcard
  | Oconst of       constant
  | Oident of       ident
  | Oconstructor of ident_cap * oexpr list
(* only allowing some patterns for now *)

and ocase = opattern * oexpr

and oexpr =
  | Onone
  | Ounit
  | Oident of   ident
  | Otuple of   oexpr list
  | Ocons of    ident_cap * oexpr list
  | Ocst of     constant
  | Ounop of    unop * oexpr
  | Obinop of   binop * oexpr * oexpr
  | Olet of     ident * oexpr * oexpr
  | Ofun of     ident * bool (* rec *) * parameter list * ret_type option
                * bool (* return pair *) * oexpr list * spec * oexpr
  | Oapp of     ident * oexpr list
  | Oif of      oexpr * oexpr * oexpr list * oexpr list
  | Ofor of     ident * oexpr * oexpr * spec option * oexpr list  
  | Owhile of   oexpr * oexpr * spec option * oexpr list
  | Oassign of  ident * ident * oexpr * oexpr (* x := 3 *)
  | Oassert of  oexpr
  | Omatch of   ident * ocase list
  | Oseq of     oexpr * oexpr

and odef = ident * bool (* rec *) * parameter list * ret_type option
           * bool (* return pair *) * oexpr list * spec

and odecl = 
  | Odef of   odef
  | Ospec of  spec
  | Otypedef of typedef
  | Oopen of    ident_cap
  | Oinclude of ident_cap
  
and ofile = odecl list
   