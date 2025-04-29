(* lex_test.ml *)
open Lexing

let () =
  let lexbuf = from_channel stdin in
  try
    while true do
      let tok = Lexer.next_token lexbuf in
      print_endline (Parser.show_token tok)
    done
  with
  | Lexer.Lexing_error msg ->
      prerr_endline ("Lexing error: " ^ msg);
      exit 1
  | End_of_file ->
      print_endline "⟦EOF⟧";
      exit 0
