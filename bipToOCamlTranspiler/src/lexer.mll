
(* Lexical analyzer for BipLang *)

{
  open Lexing
  (* open Ast *)
  open Parser

  exception Lexing_error of string

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
let ident = (letter | '_') (letter | digit | '_')*
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
  | integer as s
            { try CST (Cint (int_of_string s))
              with _ -> raise (Lexing_error ("constant too large: " ^ s)) }
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
  | _ as c  { raise (Lexing_error ("illegal character: " ^ String.make 1 c)) }

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
    | TIMES -> assert false (* TODO *)
    | THEN -> assert false (* TODO *)
    | SPEC_EQUAL -> fprintf fmt "<->"
    | RSQ -> assert false (* TODO *)
    | RP -> assert false (* TODO *)
    | RFLOOR -> fprintf fmt "_|"
    | REF -> assert false (* TODO *)
    | PRINT -> assert false (* TODO *)
    | PLUS -> assert false (* TODO *)
    | PIPE -> assert false (* TODO *)
    | OR -> assert false (* TODO *)
    | NOT -> assert false (* TODO *)
    | NEWLINE -> assert false (* TODO *)
    | MOD -> assert false (* TODO *)
    | MINUS -> assert false (* TODO *)
    | LSQ -> assert false (* TODO *)
    | LP -> assert false (* TODO *)
    | LFLOOR -> fprintf fmt "|_"
    | LET -> fprintf fmt "let"
    | INT -> assert false (* TODO *)
    | IN -> assert false (* TODO *)
    | IF -> assert false (* TODO *)
    | IDENT s -> fprintf fmt "id: %s" s
    | FOR -> assert false (* TODO *)
    | EQUAL -> assert false (* TODO *)
    | EOF -> fprintf fmt "eof"
    | END -> assert false (* TODO *)
    | ELSE -> assert false (* TODO *)
    | DONE -> assert false (* TODO *)
    | DO -> assert false (* TODO *)
    | DIV -> assert false (* TODO *)
    | DEREF -> assert false (* TODO *)
    | CST _ -> assert false (* TODO *)
    | COMMA -> assert false (* TODO *)
    | COLON -> assert false (* TODO *)
    | CMP _ -> assert false (* TODO *)
    | BOOL -> assert false (* TODO *)
    | BEGIN -> assert false (* TODO *)
    | ASSIGN -> assert false (* TODO *)
    | AND -> assert false (* TODO *)

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
   compile-command: "dune build && dune exec ./lexer.exe test.bml"
   End:
*)
