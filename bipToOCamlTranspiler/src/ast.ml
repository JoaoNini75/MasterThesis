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
  | Ecst of   constant
  | Eident of ident
  | Eunop of  unop * expr
  | Ebinop of binop * expr * expr
  (*| Elist of expr list (* [e1,e2,...] *)
  | Eget of expr * expr (* e1[e2] *) *)

and stmt =
  | Slet of     ident * expr
  | Sfun of     ident * ident list * stmt list
  | Sapp of     ident * expr list
  | Sif of      expr * stmt
  | Sifelse of  expr * stmt * stmt
  | Sfor of     ident * expr * expr * stmt (* list *)
  | Swhile of   expr * stmt (* list *)
  | Sassign of  ident * expr
  | Sset of     ident * expr
  | Sprint of   expr
  | Sfloor of   stmt
  | Spipe of    stmt * stmt
  (* | Sblock of stmt list 
  | Seval of expr
  | Sset of expr * expr * expr (* e1[e2] = e3 *) *)

(*and ast_let = ident * ident list * stmt list

 and ast_module = ast_let list * stmt *)

and file = stmt list
