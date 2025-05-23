(* Abstract Syntax of (simplified) OCaml *)

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

type oexpr =
  | Oident of   ident
  | Ocst of     constant
  | Ounop of    unop * oexpr
  | Obinop of   binop * oexpr * oexpr
  | Olet of     ident * oexpr * oexpr
  | Ofun of     def
  | Oapp of     ident * oexpr list
  | Oif of      oexpr * oexpr list * oexpr list
  | Ofor of     ident * oexpr * oexpr * oexpr list  
  | Owhile of   oexpr * oexpr list 
  | Oassign of  ident * oexpr (* x := 3 *)

and def = ident * parameter list * bip_type option * bool (* floored *) * oexpr list

and file = def list
   