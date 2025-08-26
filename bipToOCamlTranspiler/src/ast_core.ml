(* Common Abstract Syntax between BipLang and OCaml *)

(* Parsed trees.
   This is the output of the parser and the input of the interpreter. *)

type location = Lexing.position * Lexing.position

type ident = { loc: location; id: string; }
type spec = { loc: location; text: string; } (* Gospel specifications *)

type bip_type = BOOL | INT | STRING | NONE
type special_op = SOfloor | SOpipe  

type parameter = 
  | Punit
  | Param of  ident * bip_type option 
              * special_op option

type unop =
  | Uneg    (* -e *)
  | Unot    (* not e *)
  | Uref    (* ref e *)
  | Uderef  (* !e *)

type binop =
  | Badd | Bsub | Bmul | Bdiv | Bmod    (* + - * // % *)
  | Beq | Bneq | Blt | Ble | Bgt | Bge  (* == != < <= > >= *)
  | Band | Bor | Bspeq                  (* && || <-> *)

type constant =
  | Cnone
  | Cint of     int
  | Cbool of    bool
  | Cstring of  string

type pattern = 
  | Pwildcard
  | Pconst of       constant
  | Pident of       ident
  (* TODO ADD: | Pconstructor of ident *)
(* only allowing some patterns for now *)

type payload_elem =
  | PLexisting of bip_type
  | PLnew of      ident

type payload = payload_elem list

type constructor = ident * payload option

type typedef = 
  | TDsimple of ident * payload (* type ex = int * string *)
  | TDcons of   ident * constructor list (* type cons = | Cons1 | Cons2 of bool *)
  