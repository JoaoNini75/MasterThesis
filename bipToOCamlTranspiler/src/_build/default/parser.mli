
(* The type of tokens. *)

type token = 
  | WHILE
  | TIMES
  | THEN
  | SPEC_EQUAL
  | RSQ
  | RP
  | RFLOOR
  | REF
  | PRINT
  | PLUS
  | PIPE
  | OR
  | NOT
  | NEWLINE
  | MOD
  | MINUS
  | LSQ
  | LP
  | LFLOOR
  | LET
  | INT
  | IN
  | IF
  | IDENT of (string)
  | FOR
  | EQUAL
  | EOF
  | END
  | ELSE
  | DONE
  | DO
  | DIV
  | DEREF
  | CST of (Ast.constant)
  | COMMA
  | COLON
  | CMP of (Ast.binop)
  | BOOL
  | BEGIN
  | ASSIGN
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val file: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.file)
