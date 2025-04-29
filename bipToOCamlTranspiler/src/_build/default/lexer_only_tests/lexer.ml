# 4 "lexer_only_tests/lexer.mll"
 
  open Lexing
  (*open Ast*)
  open Parser

  exception Lexing_error of string

  let id_or_kwd =
    let h = Hashtbl.create 32 in
    List.iter (fun (s, tok) -> Hashtbl.add h s tok)
      ["let", LET; "if", IF; "else", ELSE;
       "then", THEN; "print", PRINT;
       "for", FOR; "while", WHILE;
       "do", DO; "done", DONE;
       "ref", REF; "in", IN; 
       "not", NOT;
       "true", CST (Cbool true);
       "false", CST (Cbool false);
       "int", INT; "bool", BOOL;
       "None", CST Cnone;];
   fun s -> try Hashtbl.find h s with Not_found -> IDENT s

  let string_buffer = Buffer.create 1024

  let stack = ref [0]  (* indentation stack *)

  let rec unindent n = match !stack with
    | m :: _ when m = n -> []
    | m :: st when m > n -> stack := st; END :: unindent n
    | _ -> raise (Lexing_error "bad indentation")

  let update_stack n =
    match !stack with
    | m :: _ when m < n ->
      stack := n :: !stack;
      [NEWLINE; BEGIN]
    | _ ->
      NEWLINE :: unindent n

# 42 "lexer_only_tests/lexer.ml"
let __ocaml_lex_tables = {
  Lexing.lex_base =
   "\000\000\223\255\224\255\000\000\001\000\001\000\233\255\078\000\
    \234\255\002\000\236\255\237\255\238\255\239\255\003\000\078\000\
    \031\000\033\000\248\255\012\000\250\255\251\255\252\255\093\000\
    \004\000\255\255\254\255\249\255\246\255\245\255\034\000\243\255\
    \225\255\241\255\232\255\230\255\229\255\013\000\226\255\227\255\
    \003\000\255\255\096\000\252\255\253\255\095\000\112\000\255\255\
    \254\255\150\000\251\255\252\255\120\000\255\255\253\255\254\255\
    ";
  Lexing.lex_backtrk =
   "\255\255\255\255\255\255\032\000\027\000\032\000\255\255\021\000\
    \255\255\020\000\255\255\255\255\255\255\255\255\013\000\011\000\
    \024\000\008\000\255\255\032\000\255\255\255\255\255\255\002\000\
    \015\000\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \001\000\255\255\255\255\255\255\255\255\002\000\002\000\255\255\
    \255\255\255\255\255\255\255\255\003\000\255\255\255\255\255\255\
    ";
  Lexing.lex_default =
   "\001\000\000\000\000\000\255\255\255\255\255\255\000\000\255\255\
    \000\000\255\255\000\000\000\000\000\000\000\000\255\255\255\255\
    \255\255\255\255\000\000\255\255\000\000\000\000\000\000\255\255\
    \255\255\000\000\000\000\000\000\000\000\000\000\255\255\000\000\
    \000\000\000\000\000\000\000\000\000\000\255\255\000\000\000\000\
    \255\255\000\000\044\000\000\000\000\000\255\255\255\255\000\000\
    \000\000\051\000\000\000\000\000\255\255\000\000\000\000\000\000\
    ";
  Lexing.lex_trans =
   "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\025\000\000\000\040\000\041\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\016\000\006\000\040\000\000\000\018\000\005\000\035\000\
    \024\000\013\000\020\000\022\000\010\000\021\000\026\000\019\000\
    \008\000\007\000\007\000\007\000\007\000\007\000\007\000\007\000\
    \007\000\007\000\009\000\027\000\015\000\017\000\014\000\034\000\
    \033\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\012\000\029\000\011\000\028\000\023\000\
    \032\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\030\000\004\000\036\000\007\000\007\000\
    \007\000\007\000\007\000\007\000\007\000\007\000\007\000\007\000\
    \045\000\048\000\046\000\031\000\037\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\039\000\
    \038\000\047\000\054\000\000\000\000\000\000\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \053\000\000\000\000\000\000\000\023\000\000\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\003\000\000\000\000\000\000\000\055\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\052\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \002\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \043\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\050\000";
  Lexing.lex_check =
   "\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\000\000\255\255\040\000\040\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\000\000\000\000\040\000\255\255\000\000\000\000\005\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\024\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\019\000\000\000\000\000\000\000\009\000\
    \014\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\016\000\000\000\017\000\000\000\
    \030\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\015\000\000\000\004\000\007\000\007\000\
    \007\000\007\000\007\000\007\000\007\000\007\000\007\000\007\000\
    \042\000\045\000\042\000\015\000\003\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\037\000\
    \037\000\046\000\052\000\255\255\255\255\255\255\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \049\000\255\255\255\255\255\255\023\000\255\255\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\000\000\255\255\255\255\255\255\052\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\049\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \042\000\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\049\000";
  Lexing.lex_base_code =
   "";
  Lexing.lex_backtrk_code =
   "";
  Lexing.lex_default_code =
   "";
  Lexing.lex_trans_code =
   "";
  Lexing.lex_check_code =
   "";
  Lexing.lex_code =
   "";
}

let rec next_tokens lexbuf =
   __ocaml_lex_next_tokens_rec lexbuf 0
and __ocaml_lex_next_tokens_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 51 "lexer_only_tests/lexer.mll"
            ( new_line lexbuf; update_stack (indentation lexbuf) )
# 196 "lexer_only_tests/lexer.ml"

  | 1 ->
# 52 "lexer_only_tests/lexer.mll"
            ( comment lexbuf; next_tokens lexbuf )
# 201 "lexer_only_tests/lexer.ml"

  | 2 ->
let
# 53 "lexer_only_tests/lexer.mll"
             id
# 207 "lexer_only_tests/lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 53 "lexer_only_tests/lexer.mll"
                ( [id_or_kwd id] )
# 211 "lexer_only_tests/lexer.ml"

  | 3 ->
# 54 "lexer_only_tests/lexer.mll"
            ( [PLUS] )
# 216 "lexer_only_tests/lexer.ml"

  | 4 ->
# 55 "lexer_only_tests/lexer.mll"
            ( [MINUS] )
# 221 "lexer_only_tests/lexer.ml"

  | 5 ->
# 56 "lexer_only_tests/lexer.mll"
            ( [TIMES] )
# 226 "lexer_only_tests/lexer.ml"

  | 6 ->
# 57 "lexer_only_tests/lexer.mll"
            ( [DIV] )
# 231 "lexer_only_tests/lexer.ml"

  | 7 ->
# 58 "lexer_only_tests/lexer.mll"
            ( [MOD] )
# 236 "lexer_only_tests/lexer.ml"

  | 8 ->
# 59 "lexer_only_tests/lexer.mll"
            ( [EQUAL] )
# 241 "lexer_only_tests/lexer.ml"

  | 9 ->
# 60 "lexer_only_tests/lexer.mll"
            ( [CMP Beq] )
# 246 "lexer_only_tests/lexer.ml"

  | 10 ->
# 61 "lexer_only_tests/lexer.mll"
            ( [CMP Bneq] )
# 251 "lexer_only_tests/lexer.ml"

  | 11 ->
# 62 "lexer_only_tests/lexer.mll"
            ( [CMP Blt] )
# 256 "lexer_only_tests/lexer.ml"

  | 12 ->
# 63 "lexer_only_tests/lexer.mll"
            ( [CMP Ble] )
# 261 "lexer_only_tests/lexer.ml"

  | 13 ->
# 64 "lexer_only_tests/lexer.mll"
            ( [CMP Bgt] )
# 266 "lexer_only_tests/lexer.ml"

  | 14 ->
# 65 "lexer_only_tests/lexer.mll"
            ( [CMP Bge] )
# 271 "lexer_only_tests/lexer.ml"

  | 15 ->
# 66 "lexer_only_tests/lexer.mll"
            ( [LP] )
# 276 "lexer_only_tests/lexer.ml"

  | 16 ->
# 67 "lexer_only_tests/lexer.mll"
            ( [RP] )
# 281 "lexer_only_tests/lexer.ml"

  | 17 ->
# 68 "lexer_only_tests/lexer.mll"
            ( [LSQ] )
# 286 "lexer_only_tests/lexer.ml"

  | 18 ->
# 69 "lexer_only_tests/lexer.mll"
            ( [RSQ] )
# 291 "lexer_only_tests/lexer.ml"

  | 19 ->
# 70 "lexer_only_tests/lexer.mll"
            ( [COMMA] )
# 296 "lexer_only_tests/lexer.ml"

  | 20 ->
# 71 "lexer_only_tests/lexer.mll"
            ( [COLON] )
# 301 "lexer_only_tests/lexer.ml"

  | 21 ->
let
# 72 "lexer_only_tests/lexer.mll"
               s
# 307 "lexer_only_tests/lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 73 "lexer_only_tests/lexer.mll"
            ( try [CST (Cint (int_of_string s))]
              with _ -> raise (Lexing_error ("constant too large: " ^ s)) )
# 312 "lexer_only_tests/lexer.ml"

  | 22 ->
# 75 "lexer_only_tests/lexer.mll"
            ( [CST (Cstring (string lexbuf))] )
# 317 "lexer_only_tests/lexer.ml"

  | 23 ->
# 77 "lexer_only_tests/lexer.mll"
            ( [ASSIGN] )
# 322 "lexer_only_tests/lexer.ml"

  | 24 ->
# 78 "lexer_only_tests/lexer.mll"
            ( [DEREF] )
# 327 "lexer_only_tests/lexer.ml"

  | 25 ->
# 79 "lexer_only_tests/lexer.mll"
            ( [AND] )
# 332 "lexer_only_tests/lexer.ml"

  | 26 ->
# 80 "lexer_only_tests/lexer.mll"
            ( [OR] )
# 337 "lexer_only_tests/lexer.ml"

  | 27 ->
# 82 "lexer_only_tests/lexer.mll"
            ( [PIPE] )
# 342 "lexer_only_tests/lexer.ml"

  | 28 ->
# 83 "lexer_only_tests/lexer.mll"
              ( [LFLOOR] )
# 347 "lexer_only_tests/lexer.ml"

  | 29 ->
# 84 "lexer_only_tests/lexer.mll"
              ( [RFLOOR] )
# 352 "lexer_only_tests/lexer.ml"

  | 30 ->
# 85 "lexer_only_tests/lexer.mll"
            ( [SPEC_EQUAL] )
# 357 "lexer_only_tests/lexer.ml"

  | 31 ->
# 87 "lexer_only_tests/lexer.mll"
            ( NEWLINE :: unindent 0 @ [EOF] )
# 362 "lexer_only_tests/lexer.ml"

  | 32 ->
let
# 88 "lexer_only_tests/lexer.mll"
         c
# 368 "lexer_only_tests/lexer.ml"
= Lexing.sub_lexeme_char lexbuf lexbuf.Lexing.lex_start_pos in
# 88 "lexer_only_tests/lexer.mll"
            ( raise (Lexing_error ("illegal character: " ^ String.make 1 c)) )
# 372 "lexer_only_tests/lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_next_tokens_rec lexbuf __ocaml_lex_state

and indentation lexbuf =
   __ocaml_lex_indentation_rec lexbuf 40
and __ocaml_lex_indentation_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 92 "lexer_only_tests/lexer.mll"
      ( new_line lexbuf; indentation lexbuf )
# 384 "lexer_only_tests/lexer.ml"

  | 1 ->
let
# 93 "lexer_only_tests/lexer.mll"
              s
# 390 "lexer_only_tests/lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 94 "lexer_only_tests/lexer.mll"
      ( String.length s )
# 394 "lexer_only_tests/lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_indentation_rec lexbuf __ocaml_lex_state

and comment lexbuf =
   __ocaml_lex_comment_rec lexbuf 42
and __ocaml_lex_comment_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 97 "lexer_only_tests/lexer.mll"
          ( () )
# 406 "lexer_only_tests/lexer.ml"

  | 1 ->
# 98 "lexer_only_tests/lexer.mll"
          ( comment lexbuf; comment lexbuf )
# 411 "lexer_only_tests/lexer.ml"

  | 2 ->
# 99 "lexer_only_tests/lexer.mll"
          ( comment lexbuf )
# 416 "lexer_only_tests/lexer.ml"

  | 3 ->
# 100 "lexer_only_tests/lexer.mll"
          ( failwith "Comment not terminated" )
# 421 "lexer_only_tests/lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_comment_rec lexbuf __ocaml_lex_state

and string lexbuf =
   __ocaml_lex_string_rec lexbuf 49
and __ocaml_lex_string_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 104 "lexer_only_tests/lexer.mll"
      ( let s = Buffer.contents string_buffer in
	Buffer.reset string_buffer;
	s )
# 435 "lexer_only_tests/lexer.ml"

  | 1 ->
# 108 "lexer_only_tests/lexer.mll"
      ( Buffer.add_char string_buffer '\n';
	string lexbuf )
# 441 "lexer_only_tests/lexer.ml"

  | 2 ->
# 111 "lexer_only_tests/lexer.mll"
      ( Buffer.add_char string_buffer '"';
	string lexbuf )
# 447 "lexer_only_tests/lexer.ml"

  | 3 ->
let
# 113 "lexer_only_tests/lexer.mll"
         c
# 453 "lexer_only_tests/lexer.ml"
= Lexing.sub_lexeme_char lexbuf lexbuf.Lexing.lex_start_pos in
# 114 "lexer_only_tests/lexer.mll"
      ( Buffer.add_char string_buffer c;
	string lexbuf )
# 458 "lexer_only_tests/lexer.ml"

  | 4 ->
# 117 "lexer_only_tests/lexer.mll"
      ( raise (Lexing_error "String not terminated") )
# 463 "lexer_only_tests/lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_string_rec lexbuf __ocaml_lex_state

;;

# 119 "lexer_only_tests/lexer.mll"
 

  let next_token =
    let tokens = Queue.create () in (* next tokens to emit *)
    fun lb ->
      if Queue.is_empty tokens then begin
    let l = next_tokens lb in
    List.iter (fun t -> Queue.add t tokens) l
        end;
        Queue.pop tokens


# 483 "lexer_only_tests/lexer.ml"
