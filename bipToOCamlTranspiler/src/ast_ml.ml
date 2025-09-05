(* Abstract Syntax of (simplified) OCaml *)

(* Parsed trees.
   This is the output of the parser and the input of the interpreter. *)

open Ast_core


type olist_def =
  | OLDsimple of  oexpr list
  | OLDid of      ident

and opattern = 
  | Owildcard
  | Oconst of       constant
  | Oident of       ident
  | Oconstructor of ident_cap * oexpr list
  | Oarray_ptrn of  array_ptrn list
(* only allowing some patterns for now *)

and ocase = opattern * oexpr

and oexpr =
  | Onone
  | Ounit
  | Oident of         ident
  | Otuple of         oexpr list
  | Ocons of          ident_cap * oexpr list
  | Ocst of           constant
  | Ounop of          unop * oexpr
  | Obinop of         binop * oexpr * oexpr
  | Olet of           ident * oexpr * oexpr
  | Ofun of           ident * bool (* rec *) * parameter list * ret_type option
                      * bool (* return pair *) * oexpr list * spec * oexpr
  | Oapp of           ident * oexpr list
  | Omodapp of        ident_cap * ident * oexpr list
  | Oif of            oexpr * oexpr * oexpr list * oexpr list
  | Ofor of           ident * oexpr * oexpr * spec option * oexpr list  
  | Owhile of         oexpr * oexpr * spec option * oexpr list
  | Oassign of        ident * ident * oexpr * oexpr (* x := 3 *)
  | Oassert of        oexpr
  | Omatch of         ident * ocase list
  | Oarray_new of     oexpr list
  | Oarray_read of    ident * oexpr
  | Oarray_write of   ident * oexpr * oexpr
  | Olist_new of      olist_def
  | Olist_concat of   olist_def * olist_def list
  | Olist_prepend of  prepend_elem list * olist_def list
  | Oseq of           oexpr * oexpr

and odef = ident * bool (* rec *) * parameter list * ret_type option
           * bool (* return pair *) * oexpr list * spec

and odecl = 
  | Odef of   odef
  | Ospec of  spec
  | Otypedef of typedef
  | Oopen of    ident_cap
  | Oinclude of ident_cap
  
and ofile = odecl list
   