
(* The type of tokens. *)

type token = 
  | WITH
  | WILDCARD
  | WHILE
  | UNIT
  | TYPE
  | TO
  | TIMES
  | THEN
  | STRING
  | SPEC of (string)
  | SEMICOLON
  | RSQBR
  | RP
  | RFLOOR
  | REF
  | REC
  | PREPEND
  | PLUS
  | PIPE
  | OPEN
  | OF
  | NOT
  | NONE
  | MOD
  | MINUS
  | MATCH
  | LSQBR
  | LP
  | LOGICOR
  | LOGICAND
  | LFLOOR
  | LET
  | INVARROW
  | INT
  | INCLUDE
  | IN
  | IF
  | IDENT_CAP of (string)
  | IDENT of (string)
  | FOR
  | EQUAL
  | EOF
  | END
  | ELSE
  | DOT
  | DONE
  | DO
  | DIV
  | DEREF
  | CST of (Ast_core.constant)
  | CONCAT_STR
  | COMMA
  | COLON
  | CMP of (Ast_core.binop)
  | CASE
  | BOOL
  | BEGIN
  | AT_SYM
  | ASSIGN
  | ASSERT
  | ARROW
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val file: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast_bip.file)
