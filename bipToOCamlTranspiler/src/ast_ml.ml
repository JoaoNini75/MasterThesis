(* Abstract Syntax of (simplified) OCaml *)

(* Parsed trees.
   This is the output of the parser and the input of the interpreter. *)

open Ast_core

type oexpr =
  | Onone
  | Ocomment of comment
  | Opars of    oexpr
  | Oident of   ident
  | Ocst of     constant
  | Ounop of    unop * oexpr
  | Obinop of   binop * oexpr * oexpr
  | Olet of     ident * oexpr * oexpr
  | Ofun of     odef
  | Oapp of     ident * oexpr list
  | Oif of      oexpr * oexpr * oexpr list * oexpr list
  | Ofor of     ident * oexpr * oexpr * oexpr list  
  | Owhile of   oexpr * oexpr * oexpr list
  | Oassign of  ident * ident * oexpr * oexpr (* x := 3 *)
  | Oseq of     oexpr * oexpr

and odef = ident * parameter list * bip_type option
           * bool (* return pair *) * oexpr list

and ofile = odef list
   