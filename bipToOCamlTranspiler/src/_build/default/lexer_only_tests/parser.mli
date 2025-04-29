(* parser.mli *)

type cmp = Beq | Bneq | Blt | Ble | Bgt | Bge

type token =
  | LET    
  | IF      | ELSE  | THEN    | PRINT
  | FOR    | WHILE   | DO    | DONE    | REF
  | IN     | AND     | OR    | NOT     | ASSIGN
  | LFLOOR | RFLOOR  | PIPE  | SPEC_EQUAL       
  | PLUS   | MINUS   | TIMES | DIV     | MOD
  | EQUAL  | DEREF   | CMP of cmp
  | LP     | RP      | LSQ   | RSQ     | COMMA
  | COLON  | NEWLINE | BEGIN | END   | EOF
  | IDENT of string
  | INT
  | BOOL
  | CST   of constant

and constant =
  | Cint of int
  | Cbool of bool
  | Cstring of string
  | Cnone

val show_token : token -> string
