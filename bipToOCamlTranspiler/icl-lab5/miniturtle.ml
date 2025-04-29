
(* Main file to interpret mini-Turtle *)

open Format
open Lexing

(* Compilation option, to stop after parsing *)
let parse_only = ref false

(* Input and output files name *)
let ifile = ref ""
let ofile = ref ""

let set_file f s = f := s

(* Compiler optios, printed using --help *)
let options =
  ["--parse-only", Arg.Set parse_only,
   "  Only performs the syntactic analysis phase"]

let usage = "usage: mini-turtle [option] file.logo"

(* Locates the error, pinpointing the line and column *)
let localisation pos =
  let l = pos.pos_lnum in
  let c = pos.pos_cnum - pos.pos_bol + 1 in
  eprintf "File \"%s\", line %d, characters %d-%d:\n" !ifile l (c-1) c

let () =
  (* Parsing the command line *)
  Arg.parse options (set_file ifile) usage;

  (* We check if the input file was correctly given *)
  if !ifile="" then begin eprintf "No file to compile\n@?"; exit 1 end;

  (* Such a file must have the .logo extension *)
  if not (Filename.check_suffix !ifile ".logo") then begin
    eprintf "The input file must have the .logo extension\n@?";
    Arg.usage options usage;
    exit 1
  end;

  (* Opening the input file for reading *)
  let f = open_in !ifile in

  (* Creating the lexial analysis buffer *)
  let buf = Lexing.from_channel f in

  try
    (* Parsing: the function [Parser.prog] transforms the lexical
       buffer into the abstract syntax tree if no error (lexical and
       syntactic) has been detected.
       Function [Lexer.token] is used by [Parser.prog] to get the next
       token. *)
    let p = Parser.prog Lexer.token buf in
    close_in f;

    (* We stop here if you only want to do parsing *)
    if !parse_only then exit 0;

    Interp.prog p
  with
    | Lexer.Lexing_error c ->
        (* Lexical error. We recover the absolute position and transform
           it into a line number *)
	localisation (Lexing.lexeme_start_p buf);
	eprintf "Erreur lexicale: %s@." c;
	exit 1
    | Parser.Error ->
        (* Syntactic error. We recover the absolute position and
           transform it into a line number *)
	localisation (Lexing.lexeme_start_p buf);
	eprintf "Erreur syntaxique@.";
	exit 1
    | Interp.Error s->
        (* Error during interpretation *)
	eprintf "Erreur : %s@." s;
	exit 1
