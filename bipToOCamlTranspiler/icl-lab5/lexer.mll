
(* Lexical analyser for mini-Turtle *)

{
  open Lexing
  open Parser

  (* exception signaling a lexical error *)
  exception Lexing_error of string

  (* note: consider calling the [Lexing.new_line] function
     for each new line character '\n' *)

}

rule token = parse
  | _      { assert false (* TODO *) }
