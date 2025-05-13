
(* Lexical analyzer for BipLang *)

{
  open Lexing
  (* open Ast *)
  open Parser

  exception Lexing_error of string

  type const =
    | Cint of int
    | Cbool of bool
    | Cstring of string

  type cmp = Beq | Bneq | Blt | Ble | Bgt | Bge

  let id_or_kwd =
    let h = Hashtbl.create 32 in
    List.iter (fun (s, tok) -> Hashtbl.add h s tok)
      [ "let", LET;
        "in", IN;
        "ref", REF;
        "if", IF;
        "then", THEN;
        "else", ELSE;
        "print", PRINT;
        "for", FOR;
        "while", WHILE;
        "do", DO;
        "done", DONE;
        "not", NOT;
        "true", CST (Cbool true);
        "false", CST (Cbool false);
        "int", INT;
        "bool", BOOL;];
   fun s -> try Hashtbl.find h s with Not_found -> IDENT s

  let string_buffer = Buffer.create 1024

}

let letter = ['a'-'z' 'A'-'Z']
let digit = ['0'-'9']
let ident = letter | ((letter | '_') (letter | digit | '_')* (letter | digit))
let integer = '0' | ['1'-'9'] digit*
let space = ' ' | '\t'

rule next_tokens = parse
  | '\n'    { new_line lexbuf; next_tokens lexbuf }
  | space+  { next_tokens lexbuf }
  | "(*"    { comment lexbuf; next_tokens lexbuf }
  | ident as id { id_or_kwd id }
  | '+'     { PLUS }
  | '-'     { MINUS }
  | '*'     { TIMES }
  | "//"    { DIV }
  | '%'     { MOD }
  | '='     { EQUAL }
  | "=="    { CMP Beq }
  | "!="    { CMP Bneq }
  | "<"     { CMP Blt }
  | "<="    { CMP Ble }
  | ">"     { CMP Bgt }
  | ">="    { CMP Bge }
  | '('     { LP }
  | ')'     { RP }
  | '['     { LSQ }
  | ']'     { RSQ }
  | ','     { COMMA }
  | ':'     { COLON }
  | ';'     { SEMICOLON }
  | integer as s
            { try CST (Cint (int_of_string s))
              with _ -> raise (Lexing_error ("Constant too large: " ^ s)) }
  | '"'     { CST (Cstring (string lexbuf)) }

  | ":="    { ASSIGN }
  | "!"     { DEREF }
  | "&&"    { AND }
  | "||"    { OR }

  | '|'     { PIPE }
  | "|_"    { LFLOOR }
  | "_|"    { RFLOOR }
  | "<->"   { SPEC_EQUAL }

  | eof     { EOF }
  | _ as c  { raise (Lexing_error ("Illegal character: " ^ String.make 1 c)) }

and comment = parse
  | "*)"  { () }
  | "(*"  { comment lexbuf; comment lexbuf }
  | _     { comment lexbuf }
  | eof   { failwith "Comment not terminated" }

and string = parse
  | '"'
      { let s = Buffer.contents string_buffer in
	Buffer.reset string_buffer;
	s }
  | "\\n"
      { Buffer.add_char string_buffer '\n';
	string lexbuf }
  | "\\\""
      { Buffer.add_char string_buffer '"';
	string lexbuf }
  | _ as c
      { Buffer.add_char string_buffer c;
	string lexbuf }
  | eof
      { raise (Lexing_error "String not terminated") }

{

  let next_token =
    let tokens = Queue.create () in (* next tokens to emit *)
    fun lb ->
      if Queue.is_empty tokens then begin
        let l = next_tokens lb in
        Queue.add l tokens
      end;
      Queue.pop tokens

  open Format

  let pp_token fmt (t: token) =
    match t with
    | WHILE -> fprintf fmt "while"
    | TIMES -> fprintf fmt "times"
    | THEN -> fprintf fmt "then"
    | SPEC_EQUAL -> fprintf fmt "<->"
    | RSQ -> fprintf fmt "]"
    | RP -> fprintf fmt ")"
    | RFLOOR -> fprintf fmt "_|"
    | REF -> fprintf fmt "ref"
    | PRINT -> fprintf fmt "print"
    | PLUS -> fprintf fmt "+"
    | PIPE -> fprintf fmt "|"
    | OR -> fprintf fmt "or"
    | NOT -> fprintf fmt "not"
    | NEWLINE -> fprintf fmt "newline"
    | MOD -> fprintf fmt "mod"
    | MINUS -> fprintf fmt "-"
    | LSQ -> fprintf fmt "["
    | LP -> fprintf fmt "("
    | LFLOOR -> fprintf fmt "|_"
    | LET -> fprintf fmt "let"
    | INT -> fprintf fmt "int"
    | IN -> fprintf fmt "in"
    | IF -> fprintf fmt "if"
    | IDENT s -> fprintf fmt "%s (identifier)" s
    | FOR -> fprintf fmt "for"
    | EQUAL -> fprintf fmt "="
    | EOF -> fprintf fmt "eof"
    | END -> fprintf fmt "end"
    | ELSE -> fprintf fmt "else"
    | DONE -> fprintf fmt "done"
    | DO -> fprintf fmt "do"
    | DIV -> fprintf fmt "/"
    | DEREF -> fprintf fmt "!"
    | CST c ->
      let s =
        match c with
        | Cint  i -> string_of_int i
        | Cbool b -> string_of_bool b
        | Cstring str -> str
        | Cnone -> "Cnone"
      in
      fprintf fmt "%s (const)" s

    | COMMA -> fprintf fmt ","
    | COLON -> fprintf fmt ":"
    | SEMICOLON -> fprintf fmt ";"
    | CMP op ->
      let s =
        match op with
        | Beq  -> "=="
        | Bneq -> "!="
        | Blt  -> "<"
        | Ble  -> "<="
        | Bgt  -> ">"
        | Bge  -> ">="
      in
      fprintf fmt "%s (cmp)" s

    | BOOL -> fprintf fmt "bool"
    | BEGIN -> fprintf fmt "begin"
    | ASSIGN -> fprintf fmt ":="
    | AND -> fprintf fmt "and"

  let () =
    let fname = Sys.argv.(1) in
    let cin = open_in fname in
    let lb = Lexing.from_channel cin in
    let rec loop () =
      let token : Parser.token = next_token lb in
      eprintf "@[%a@]@." pp_token token;
      if token <> EOF then loop () in
    loop ()

}

(*
   Local Variables:
   compile-command: "dune build && dune exec ./lexer.exe lexer_test.bml"
   End:
*)
