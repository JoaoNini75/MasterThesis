(* Main program *)

open Format
open Lexing
open Parser
open Ast_bip
open Ast_ml

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



let get_const_str (const : Ast_ml.constant) = 
  match const with
  | Cint  i -> string_of_int i
  | Cbool b -> string_of_bool b
  | Cstring str -> str
  | Cnone -> "Cnone"

let get_unop_str (unop : Ast_ml.unop) =
  match unop with
    | Uneg -> "-"
    | Unot -> "not "
    | Uref -> "ref "
    | Uderef -> "!" 

let get_binop_str (binop : Ast_ml.binop) =
  match binop with
    | Badd -> "+"
    | Bsub -> "-"
    | Bmul -> "*" 
    | Bdiv -> "/" 
    | Bmod -> "mod"   
    | Beq -> "=" 
    | Bneq -> "<>" 
    | Blt -> "<" 
    | Ble -> "<=" 
    | Bgt -> ">" 
    | Bge -> ">="  
    | Band -> "and" 
    | Bor -> "or" 
    | Bspeq -> "<->"

let get_type_str (bip_type_opt : Ast_ml.bip_type option) =
  match bip_type_opt with
  | None -> ""
  | Some bt -> 
    match bt with
    | INT -> "int"
    | BOOL -> "bool"
    | NONE -> ""


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
and pp_expr fmt (expr : Ast_bip.expr) = 
  match expr with
  | Eident id -> fprintf fmt "%s (expr.id) " id.id
  | Ecst c -> pp_constant fmt c
  | Eunop (op, e) -> pp_unop fmt op e
  | Ebinop (op, e1, e2) -> pp_binop fmt op e1 e2
  | Elet (id, value, body) -> 
    fprintf fmt "\n(let) %s = " id.id;
    pp_expr fmt value;
    fprintf fmt "in";
    pp_expr fmt body
  | Efun (id, param_list, fun_type, floored, expr_list) ->
    pp_def fmt (id, param_list, fun_type, floored, expr_list)
  | Eapp (id, expr_list) -> 
    fprintf fmt "\n(app) id = %s, expr_list: " id.id;
    List.iter (fun expr -> pp_expr fmt expr) expr_list
  | Eif (cnd, s1, s2) -> 
    fprintf fmt "\n(if) "; 
    pp_expr fmt cnd; 
    fprintf fmt "\n(then) ";
    List.iter (fun expr -> pp_expr fmt expr) s1;
    fprintf fmt "\n(else) ";
    List.iter (fun expr -> pp_expr fmt expr) s2
  | Efor (id, value, e_to, body) -> 
    fprintf fmt "\n(for) id = %s, val = " id.id; 
    pp_expr fmt value;     
    fprintf fmt "to ";         
    pp_expr fmt e_to; 
    fprintf fmt "do"; 
    List.iter (fun expr -> pp_expr fmt expr) body;
    fprintf fmt "done";
  | Ewhile (cnd, body) -> 
    fprintf fmt "\n(while) "; 
    pp_expr fmt cnd; 
    fprintf fmt "do"; 
    List.iter (fun expr -> pp_expr fmt expr) body;
    fprintf fmt "done";
  | Eassign (id, e) -> 
    fprintf fmt "\n(assign) %s := " id.id;
    pp_expr fmt e
  | Efloor e -> 
    fprintf fmt "\n(floor) |_ ";
    pp_expr fmt e;
    fprintf fmt "_| "
  | Epipe (e1, e2) -> 
    fprintf fmt "\n(pipe) ";
    pp_expr fmt e1;
    fprintf fmt " | ";
    pp_expr fmt e2
  | Eflrlet (id, value) ->
    fprintf fmt "\n(flrlet) |_ %s = " id.id;
    pp_expr fmt value;
    fprintf fmt "in _| ";
  | Epipelet (id1, value1, id2, value2) -> 
    fprintf fmt "\n(pipelet) %s = " id1.id;
    pp_expr fmt value1;
    fprintf fmt "in | %s = " id2.id;
    pp_expr fmt value2;
    fprintf fmt "in "
and pp_def fmt def =
  let (id, param_list, fun_type, floored, expr_list) = def in
  fprintf fmt "\n\n(fun) id: %s, type: %a, %a (def.id_list): " id.id pp_type_option fun_type pp_floored floored;
  
  List.iter (
    fun (ident, bip_type_opt, floored) ->
      fprintf fmt "%s (%a, %a), " 
      ident.id pp_type_option bip_type_opt pp_floored floored
  ) param_list;

  List.iter (fun expr -> pp_expr fmt expr) expr_list
and pp_oexpr fmt oexpr = 
  match oexpr with
  | Oident id -> fprintf fmt "%s" id.id
  | Ocst c -> fprintf fmt "%s" (get_const_str c)
  | Ounop (op, e) -> 
    fprintf fmt "%s" (get_unop_str op);
    pp_oexpr fmt e
  | Obinop (op, e1, e2) -> 
    pp_oexpr fmt e1;
    fprintf fmt " %s " (get_binop_str op);
    pp_oexpr fmt e2
  | Olet (id, value, body) -> 
    fprintf fmt "let %s = " id.id;
    pp_oexpr fmt value;
    fprintf fmt " in\n";
    pp_oexpr fmt body
  | Ofun (id, param_list, fun_type, floored, oexpr_list) ->
    pp_def_ml fmt (id, param_list, fun_type, floored, oexpr_list)
  | Oapp (id, oexpr_list) -> 
    fprintf fmt "%s " id.id;
    List.iter (fun oexpr -> fprintf fmt "%a " pp_oexpr fmt oexpr) oexpr_list
  | Oif (cnd, s1, s2) -> 
    fprintf fmt "if "; 
    pp_oexpr fmt cnd; 
    fprintf fmt "\nthen ";
    List.iter (fun oexpr -> pp_oexpr fmt oexpr) s1;
    fprintf fmt "\nelse ";
    List.iter (fun oexpr -> pp_oexpr fmt oexpr) s2
  | Ofor (id, value, e_to, body) -> 
    fprintf fmt "for %s = %a to %a do\n" id.id (pp_oexpr fmt value) (pp_oexpr fmt e_to); 
    List.iter (fun oexpr -> pp_oexpr fmt oexpr) body;
    fprintf fmt "\ndone ";
  | Owhile (cnd, body) -> 
    fprintf fmt "while %a do\n" (pp_oexpr fmt cnd); 
    List.iter (fun expr -> pp_oexpr fmt expr) body;
    fprintf fmt "\ndone ";
  | Oassign (id, e) -> fprintf fmt "%s := %a" id.id (pp_oexpr fmt e);
  | Ofloor e -> 
    fprintf fmt "\n(floor) |_ ";
    pp_oexpr fmt e;
    fprintf fmt "_| "
  | Opipe (e1, e2) -> 
    fprintf fmt "\n(pipe) ";
    pp_oexpr fmt e1;
    fprintf fmt " | ";
    pp_oexpr fmt e2
  | Oflrlet (id, value) ->
    fprintf fmt "\n(flrlet) |_ %s = " id.id;
    pp_oexpr fmt value;
    fprintf fmt "in _| ";
  | Opipelet (id1, value1, id2, value2) -> 
    fprintf fmt "\n(pipelet) %s = " id1.id;
    pp_oexpr fmt value1;
    fprintf fmt "in | %s = " id2.id;
    pp_oexpr fmt value2;
    fprintf fmt "in "
and pp_def_ml fmt def =
  let (id, param_list, fun_type, fun_floored, oexpr_list) = def in
  let fun_type_str = get_type_str fun_type in

  fprintf fmt "let %s (" id.id;
  
  List.iter (
    fun (ident, param_type, floored) ->
      let param_type_str = get_type_str param_type in

      if floored then (
        let id1 = ident.id ^ "_l" in
        let id2 = ident.id ^ "_r" in

        if param_type_str = "" 
        then fprintf fmt "%s, %s, " id1 id2
        else fprintf fmt "%s : %s, %s : %s" id1 param_type_str id2 param_type_str
      ) else (
        if param_type_str = "" 
        then fprintf fmt "%s," ident.id
        else fprintf fmt "%s : %s, " ident.id param_type_str 
      )
  ) param_list;

  if fun_type_str = "" then (
    fprintf fmt ") = begin\n"
  ) else (
    if fun_floored
    then (fprintf fmt ") : (%s, %s) = begin\n" fun_type_str fun_type_str)
    else (fprintf fmt ") : %s = begin\n" fun_type_str)
  );

  List.iter (fun oexpr -> pp_oexpr fmt oexpr) oexpr_list;

  fprintf fmt "\nend\n\n"
  

let pp_file fmt (file : Ast_bip.file) =
  fprintf fmt "\n\nParser output:";
  List.iter (pp_def fmt) file

let pp_ast ast =
  eprintf "@[%a@]@." pp_file ast


let pp_file_ml fmt (file : Ast_ml.file) =
  fprintf fmt "\n\nOCaml code:";
  List.iter (pp_def_ml fmt) file

let pp_ast_to_ml ast =
  eprintf "@[%a@]@." pp_file_ml ast


let () =
  let c = open_in file in
  let lb = Lexing.from_channel c in
  try
    let f = Parser.file Lexer.next_token lb in
    close_in c;
    pp_ast f;
    pp_ast_to_ml f;

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
