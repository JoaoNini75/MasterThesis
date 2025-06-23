(* Common Abstract Syntax between BipLang and OCaml *)

(* Parsed trees.
   This is the output of the parser and the input of the interpreter. *)

type location = Lexing.position * Lexing.position

type ident = { loc: location; id: string; }
type spec = { loc: location; text: string; } (* Gospel specifications *)

type bip_type = BOOL | INT | NONE
type special_op = SOfloor | SOpipe  
type parameter = ident * bip_type option * special_op option
  
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
  | Cunit
  | Cint of     int
  | Cbool of    bool
  | Cstring of  string
