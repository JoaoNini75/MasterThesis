
(* Lexical analyzer for BipLang *)

{
  open Lexing
  open Ast_bip
  open Parser

  exception Lexing_error of string

  let is_first_uppercase_ascii s =
    match s.[0] with
    | 'A' .. 'Z' -> true
    | _ -> false

  let id_or_kwd =
    let h = Hashtbl.create 32 in
    List.iter (fun (s, tok) -> Hashtbl.add h s tok)
      [ "let", LET;
        "in", IN;
        "ref", REF;
        "if", IF;
        "then", THEN;
        "else", ELSE;
        "for", FOR;
        "while", WHILE;
        "to", TO;
        "do", DO;
        "done", DONE;
        "begin", BEGIN;
        "end", END;
        "not", NOT;
        "true", CST (Cbool true);
        "false", CST (Cbool false);
        "mod", MOD;
        "int", INT;
        "bool", BOOL;
        "string", STRING;
        "None", NONE;
        "rec", REC;
        "assert", ASSERT;
        "match", MATCH;
        "with", WITH;
        "type", TYPE;
        "of", OF;
        "and", AND;
        "open", OPEN;
        "include", INCLUDE];
    fun s -> try Hashtbl.find h s with Not_found -> 
      if is_first_uppercase_ascii s
      then IDENT_CAP s
      else IDENT s

  let string_buffer = Buffer.create 1024
  let spec_buf = Buffer.create 1024
}

let letter = ['a'-'z' 'A'-'Z']
let letter_lc = ['a'-'z']
let letter_uc = ['A'-'Z']
let digit = ['0'-'9']
let ident = letter_lc | ((letter | '_') (letter | digit | '_')* (letter | digit))
let ident_cap = letter_uc | ((letter | '_') (letter | digit | '_')* (letter | digit))
let integer = '0' | ['1'-'9'] digit*
let space = ' ' | '\t'

rule next_tokens = parse
  | '\n'    { new_line lexbuf; next_tokens lexbuf }
  | space+  { next_tokens lexbuf }

  | "(*@"
    {
      Buffer.clear spec_buf; 
      gather_spec lexbuf
    }
  
  | "(*"       
    {
      skip_comment 1 lexbuf;
      next_tokens lexbuf
    }
  
  | ident as id { id_or_kwd id }
  | ident_cap as id { id_or_kwd id }
  | '+'     { PLUS }
  | '-'     { MINUS }
  | '*'     { TIMES }
  | "/"     { DIV }
  | '='     { EQUAL }
  | "=="    { CMP Beqphy }
  | "<>"    { CMP Bneq }
  | "!="    { CMP Bneqphy }
  | "<"     { CMP Blt }
  | "<="    { CMP Ble }
  | ">"     { CMP Bgt }
  | ">="    { CMP Bge }
  | "&&"    { LOGICAND }
  | "||"    { LOGICOR }
  | '('     { LP }
  | ')'     { RP }
  | ','     { COMMA }
  | ':'     { COLON }
  | ';'     { SEMICOLON }
  | integer as s
            { try CST (Cint (int_of_string s))
              with _ -> raise (Lexing_error ("Constant too large: " ^ s)) }
  | '"'     { CST (Cstring (string lexbuf)) }
  | ":="    { ASSIGN }
  | "!"     { DEREF }
  | "()"    { UNIT }
  | '|'     { CASE }  

  | "<|>"   { PIPE }     
  | "|_"    { LFLOOR }      
  | "_|"    { RFLOOR }      
  | "."     { DOT }

  | "->"    { ARROW }
  | "_"     { WILDCARD }
  | "["     { LSQBR }
  | "]"     { RSQBR }
  | "<-"    { INVARROW }
  | "@"     { CONCAT }
  | "::"    { PREPEND }
  | "^"     { CONCAT_STR }

  | eof     { EOF }
  | _ as c  { raise (Lexing_error ("Illegal character: " ^ String.make 1 c)) }

and skip_comment depth = parse
  | "(*"  { skip_comment (depth + 1) lexbuf; skip_comment (depth + 1) lexbuf }
  | "*)"  { () }  (* matched the close; return to `token` *)
  | eof   { raise (Lexing_error "Unterminated comment") }
  | _     { skip_comment depth lexbuf }

and gather_spec = parse      
  | "*)"    { SPEC (Buffer.contents spec_buf) }
  | eof     { raise (Lexing_error "Unterminated specification ") }
  | _ as c  { Buffer.add_char spec_buf c; gather_spec lexbuf }

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
    | RP -> fprintf fmt ")"
    | RFLOOR -> fprintf fmt "_|"
    | REF -> fprintf fmt "ref"
    | PLUS -> fprintf fmt "+"
    | CASE -> fprintf fmt "|"
    | PIPE -> fprintf fmt "<|>" 
    | NOT -> fprintf fmt "not"
    | LOGICAND -> fprintf fmt "&&"
    | LOGICOR -> fprintf fmt "||"
    | MOD -> fprintf fmt "mod"
    | MINUS -> fprintf fmt "-"
    | LP -> fprintf fmt "("
    | LFLOOR -> fprintf fmt "|_"
    | LET -> fprintf fmt "let"
    | INT -> fprintf fmt "int"
    | STRING -> fprintf fmt "string"
    | IN -> fprintf fmt "in"
    | IF -> fprintf fmt "if"
    | IDENT s -> fprintf fmt "%s (identifier)" s
    | IDENT_CAP s -> fprintf fmt "%s (ident_cap)" s
    | FOR -> fprintf fmt "for"
    | EQUAL -> fprintf fmt "="
    | EOF -> fprintf fmt "eof"
    | END -> fprintf fmt "end"
    | ELSE -> fprintf fmt "else"
    | DONE -> fprintf fmt "done"
    | DO -> fprintf fmt "do"
    | TO -> fprintf fmt "to"
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

    | UNIT -> fprintf fmt "unit"
    | COMMA -> fprintf fmt ","
    | COLON -> fprintf fmt ":"
    | SEMICOLON -> fprintf fmt ";"
    | DOT -> fprintf fmt "."
    | CMP op ->
      let s =
        match op with
        | Beqphy  -> "=="
        | Bneqphy -> "!=" 
        | Bneq -> "<>"
        | Blt  -> "<"
        | Ble  -> "<="
        | Bgt  -> ">"
        | Bge  -> ">="
        | _ -> assert false
      in
      fprintf fmt "%s (cmp)" s

    | BOOL -> fprintf fmt "bool"
    | BEGIN -> fprintf fmt "begin"
    | ASSIGN -> fprintf fmt ":="
    | NONE -> fprintf fmt "none"
    | SPEC s -> fprintf fmt "%s (specification)" s
    | REC -> fprintf fmt "rec"
    | ASSERT -> fprintf fmt "assert"
    | MATCH -> fprintf fmt "match"
    | WITH -> fprintf fmt "with"
    | ARROW -> fprintf fmt "->"
    | WILDCARD -> fprintf fmt "_"
    | TYPE -> fprintf fmt "type"
    | OF -> fprintf fmt "of"
    | AND -> fprintf fmt "and"
    | OPEN -> fprintf fmt "open"
    | INCLUDE -> fprintf fmt "include"
    | LSQBR -> fprintf fmt "["
    | RSQBR -> fprintf fmt "]"
    | INVARROW -> fprintf fmt "<-"
    | CONCAT -> fprintf fmt "@"
    | PREPEND -> fprintf fmt "::"
    | CONCAT_STR -> fprintf fmt "^"

  let () =
    let fname = Sys.argv.(1) in
    let cin = open_in fname in
    let lb = Lexing.from_channel cin in
    let rec loop () =
      let token : Parser.token = next_token lb in
        (* eprintf "@[%a@]@." pp_token token; *)
      if token <> EOF then loop () in
    loop ()

}

(*
   Local Variables:
   compile-command: "dune build && dune exec ./lexer.exe lexer_test.bip"
   End:
*)
