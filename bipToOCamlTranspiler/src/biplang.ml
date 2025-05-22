(* Main program *)

open Format
open Lexing
open Parser
open Ast

let usage = "usage: biplang [options] file.bip"
(* dune build && dune exec ./biplang.exe parser_test.bip *)

let parse_only = ref false

let spec =
  [
    "--parse-only", Arg.Set parse_only, "  stop after parsing";
  ]

let file =
  let file = ref None in
  let set_file s =
    if not (Filename.check_suffix s ".bip") then
      raise (Arg.Bad "no .bip extension");
    file := Some s
  in
  Arg.parse spec set_file usage;
  match !file with Some f -> f | None -> Arg.usage spec usage; exit 1

let report (b,e) =
  let l = b.pos_lnum in
  let fc = b.pos_cnum - b.pos_bol + 1 in
  let lc = e.pos_cnum - b.pos_bol + 1 in
  eprintf "File \"%s\", line %d, characters %d-%d:\n" file l fc lc


let pp_floored fmt floored =
  if floored 
  then fprintf fmt "floored"
  else fprintf fmt "not_floored"

let pp_type fmt bip_type =
  match bip_type with
  | INT -> fprintf fmt "int"
  | BOOL -> fprintf fmt "bool"
  | NONE -> fprintf fmt "None"

let pp_type_option fmt bip_type_opt =
  match bip_type_opt with
  | None -> fprintf fmt "implicit"
  | Some bt -> pp_type fmt bt

let pp_constant fmt constant =
  let s =
    match constant with
      | Cint  i -> string_of_int i
      | Cbool b -> string_of_bool b
      | Cstring str -> str
      | Cnone -> "Cnone"
  in 
    fprintf fmt "%s (constant) " s


let rec pp_unop fmt unop e =
  let pp_unop_aux fmt s =
    match unop with
      | Uneg -> fprintf fmt "-"
      | Unot -> fprintf fmt "not"
      | Uref -> fprintf fmt "ref"
      | Uderef -> fprintf fmt "!" 
  in
  fprintf fmt "(unop %a) " pp_unop_aux unop;
  pp_expr fmt e
and pp_binop fmt binop e1 e2 =
  let s =
    match binop with
      | Badd -> "add"
      | Bsub -> "sub"
      | Bmul -> "mul" 
      | Bdiv -> "div" 
      | Bmod -> "mod"   
      | Beq -> "eq" 
      | Bneq -> "neq" 
      | Blt -> "<" 
      | Ble -> "<=" 
      | Bgt -> ">" 
      | Bge -> ">="  
      | Band -> "and" 
      | Bor -> "or" 
      | Bspeq -> "<->"
  in
    fprintf fmt "(binop %s) " s;
    pp_expr fmt e1;
    pp_expr fmt e2
and pp_expr fmt expr = 
  match expr with
  | Eident id -> fprintf fmt "%s (expr.id) " id.id
  | Ecst c -> pp_constant fmt c
  | Eunop (op, e) -> pp_unop fmt op e
  | Ebinop (op, e1, e2) -> pp_binop fmt op e1 e2
  | Slet (id, value, body) -> 
    fprintf fmt "\n(let) %s = " id.id;
    pp_expr fmt value;
    fprintf fmt "in";
    pp_expr fmt body
  | Sfun (id, param_list, fun_type, floored, expr_list) ->
    pp_def fmt (id, param_list, fun_type, floored, expr_list)
  | Sapp (id, expr_list) -> 
    fprintf fmt "\n(app) id = %s, expr_list: " id.id;
    List.iter (fun expr -> pp_expr fmt expr) expr_list
  | Sif (cnd, s1, s2) -> 
    fprintf fmt "\n(if) "; 
    pp_expr fmt cnd; 
    fprintf fmt "\n(then) ";
    List.iter (fun expr -> pp_expr fmt expr) s1;
    fprintf fmt "\n(else) ";
    List.iter (fun expr -> pp_expr fmt expr) s2
  | Sfor (id, value, e_to, body) -> 
    fprintf fmt "\n(for) id = %s, val = " id.id; 
    pp_expr fmt value;     
    fprintf fmt "to ";         
    pp_expr fmt e_to; 
    fprintf fmt "do"; 
    List.iter (fun expr -> pp_expr fmt expr) body;
    fprintf fmt "done";
  | Swhile (cnd, body) -> 
    fprintf fmt "\n(while) "; 
    pp_expr fmt cnd; 
    fprintf fmt "do"; 
    List.iter (fun expr -> pp_expr fmt expr) body;
    fprintf fmt "done";
  | Sset (id, e) -> 
    fprintf fmt "\n(set) %s := " id.id;
    pp_expr fmt e
  | Sfloor e -> 
    fprintf fmt "\n(floor) ";
    pp_expr fmt e
  | Spipe (e1, e2) -> 
    fprintf fmt "\n(pipe) ";
    pp_expr fmt e1;
    fprintf fmt " | ";
    pp_expr fmt e2
and pp_def fmt def =
  let (id, param_list, fun_type, floored, expr_list) = def in
  fprintf fmt "\n\n(fun) id: %s, type: %a, %a (def.id_list): " id.id pp_type_option fun_type pp_floored floored;
  
  List.iter (
    fun (ident, bip_type_opt, floored) ->
      fprintf fmt "%s (%a, %a), " 
      ident.id pp_type_option bip_type_opt pp_floored floored
  ) param_list;

  List.iter (fun expr -> pp_expr fmt expr) expr_list
  

let pp_file fmt file =
  fprintf fmt "\n\nParser output:";
  List.iter (pp_def fmt) file

let pp_ast ast =
  eprintf "@[%a@]@." pp_file ast


let () =
  let c = open_in file in
  let lb = Lexing.from_channel c in
  try
    let f = Parser.file Lexer.next_token lb in
    close_in c;
    pp_ast f;

    if !parse_only then exit 0
  with
    | Lexer.Lexing_error s ->
	report (lexeme_start_p lb, lexeme_end_p lb);
	eprintf "lexical error: %s@." s;
	exit 1
    | Parser.Error ->
	report (lexeme_start_p lb, lexeme_end_p lb);
	eprintf "syntax error@.";
	exit 1
    | e ->
	eprintf "Anomaly: %s\n@." (Printexc.to_string e);
	exit 2
