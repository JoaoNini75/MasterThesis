(* Main program *)

open Format
open Lexing
open Parser
open Ast_ml
open Ast_bip
open Ast_core

type side = Left | Right

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

let rec bip_to_ml_def (def: Ast_bip.def) : Ast_ml.odef =
  let (ident, param_list, bto, special_op_opt, body) = def in
  (ident, param_list, bto, special_op_opt <> None,
    List.map (fun e -> bip_to_ml e None) body)
and bip_to_ml (e: Ast_bip.expr) (side: side option) : Ast_ml.oexpr =
  match e with  
  | Eident ident -> (
    match side with
    | None -> Oident ident
    | Some Left -> Oident ({ ident with id = ident.id ^ "_l" })
    | Some Right -> Oident ({ ident with id = ident.id ^ "_r" }))

  | Ecst c -> Ocst c

  | Eunop (op, e) -> Ounop (op, bip_to_ml e side)

  | Ebinop (op, e1, e2) -> 
    Obinop (op, (bip_to_ml e1 side), (bip_to_ml e2 side))

  | Elet (ident, Efloor e1, e2) ->
    let ident_l = { ident with id = ident.id ^ "_l"} 
    and ident_r = { ident with id = ident.id ^ "_r"}
    and oe1_l = bip_to_ml e1 (Some Left)
    and oe1_r = bip_to_ml e1 (Some Right)  
    and oe2 = bip_to_ml e2 None in
    Olet (ident_l, oe1_l, Olet (ident_r, oe1_r, oe2))

  | Elet (ident, Epipe (e1, e2), e_body) ->
    let ident_l = { ident with id = ident.id ^ "_l"} in
    let ident_r = { ident with id = ident.id ^ "_r"} in
    let oe1 = bip_to_ml e1 (Some Left) in
    let oe2 = bip_to_ml e2 (Some Right) in
    let oe_body = bip_to_ml e_body None in
    Olet (ident_l, oe1, Olet(ident_r, oe2, oe_body))

  | Elet (x, e1, e2) -> 
    Olet (x, bip_to_ml e1 None, bip_to_ml e2 None)

  | Efun def -> Ofun (bip_to_ml_def def) 

  | Eapp (ident, expr_list) -> 
    Oapp (ident, (List.map (fun e -> bip_to_ml e None) expr_list))

  | Eif (Efloor e_cnd, el_then, el_else) ->
    let oe_cnd_l = bip_to_ml e_cnd (Some Left)
    and oe_cnd_r = bip_to_ml e_cnd (Some Right)
    and oel_then = List.map (fun e -> bip_to_ml e None) el_then
    and oel_else = List.map (fun e -> bip_to_ml e None) el_else in
    Oif (oe_cnd_l, oe_cnd_r, oel_then, oel_else)

  | Eif (Epipe (e_cnd1, e_cnd2), el_then, el_else) ->
    let oe_cnd_l = bip_to_ml e_cnd1 (Some Left)
    and oe_cnd_r = bip_to_ml e_cnd2 (Some Right)
    and oel_then = List.map (fun e -> bip_to_ml e None) el_then
    and oel_else = List.map (fun e -> bip_to_ml e None) el_else in
    Oif (oe_cnd_l, oe_cnd_r, oel_then, oel_else)

  | Eif (e_cnd, el_then, el_else) ->
    let oe_cnd = bip_to_ml e_cnd None
    and oel_then = List.map (fun e -> bip_to_ml e None) el_then
    and oel_else = List.map (fun e -> bip_to_ml e None) el_else in
    Oif (oe_cnd, Onone, oel_then, oel_else)

  | Efor (ident, e_val, e_to, el_body) ->
    let oe_val = bip_to_ml e_val None 
    and oe_to = bip_to_ml e_to None 
    and oel_body = List.map (fun e -> bip_to_ml e None) el_body in
    Ofor (ident, oe_val, oe_to, oel_body)

  | Ewhile (Efloor e_cnd, el_body) ->
    let oe_cnd_l = bip_to_ml e_cnd (Some Left)
    and oe_cnd_r = bip_to_ml e_cnd (Some Right)
    and oel_body = List.map (fun e -> bip_to_ml e None) el_body in
    Owhile (oe_cnd_l, oe_cnd_r, oel_body)

  | Ewhile (Epipe (e_cnd1, e_cnd2), el_body) ->
    let oe_cnd_l = bip_to_ml e_cnd1 (Some Left)
    and oe_cnd_r = bip_to_ml e_cnd2 (Some Right)
    and oel_body = List.map (fun e -> bip_to_ml e None) el_body in
    Owhile (oe_cnd_l, oe_cnd_r, oel_body)

  | Ewhile (e_cnd, el_body) ->
    let oe_cnd = bip_to_ml e_cnd None
    and oel_body = List.map (fun e -> bip_to_ml e None) el_body in
    Owhile (oe_cnd, Onone, oel_body)

  | Eassign (ident, Efloor e) ->
    let ident_l = { ident with id = ident.id ^ "_l"} in
    let ident_r = { ident with id = ident.id ^ "_r"} in
    Oassign (ident_l, ident_r, bip_to_ml e (Some Left), bip_to_ml e (Some Right))

  | Eassign (ident, Epipe (e1, e2)) -> 
    let ident_l = { ident with id = ident.id ^ "_l"} in
    let ident_r = { ident with id = ident.id ^ "_r"} in
    Oassign (ident_l, ident_r, bip_to_ml e1 (Some Left), bip_to_ml e2 (Some Right)) 

  | Eassign (ident, e) ->
    ( match side with 
      | None -> Oassign (ident, ident, bip_to_ml e side, Onone)
      | Some Left -> 
        let ident_l = { ident with id = ident.id ^ "_l"} in
        Oassign (ident_l, ident_l, bip_to_ml e side, Onone)
      | Some Right -> 
        let ident_r = { ident with id = ident.id ^ "_r"} in
        Oassign (ident_r, ident_r, bip_to_ml e side, Onone) )
     
  | Efloor e -> bip_to_ml (Epipe (e, e)) None 

  | Epipe (e1, e2) -> Oseq(bip_to_ml e1 (Some Left), bip_to_ml e2 (Some Right))
    
  (*| Eflrlet of  ident * expr (* |_ let x = 2 in _| *)
  | Epipelet of ident * expr * ident * expr (* let x = 2 in | let x = 3 in *) *)


let get_const_str (const : Ast_core.constant) = 
  match const with
  | Cint  i -> string_of_int i
  | Cbool b -> string_of_bool b
  | Cstring str -> str
  | Cnone -> "Cnone"

let get_unop_str (unop : Ast_core.unop) =
  match unop with
    | Uneg -> "-"
    | Unot -> "not "
    | Uref -> "ref "
    | Uderef -> "!" 

let get_binop_str (binop : Ast_core.binop) =
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

let get_type_str (bip_type_opt : Ast_core.bip_type option) =
  match bip_type_opt with
  | None -> ""
  | Some bt -> 
    match bt with
    | INT -> "int"
    | BOOL -> "bool"
    | NONE -> ""


let pp_special_op fmt special_op_opt =
  match special_op_opt with 
  | None -> fprintf fmt "normal"
  | Some SOfloor -> fprintf fmt "floored"
  | Some SOpipe -> fprintf fmt "piped"

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

let indent depth =
  String.make (depth * 2) ' '


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
  | Elet (id, value, body) -> 
    fprintf fmt "\n(let) %s = " id.id;
    pp_expr fmt value;
    fprintf fmt "in";
    pp_expr fmt body
  | Efun (id, param_list, fun_type, special_op_opt, expr_list) ->
    pp_def fmt (id, param_list, fun_type, special_op_opt, expr_list)
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
  (*| Eflrlet (id, value) ->
    fprintf fmt "\n(flrlet) |_ %s = " id.id;
    pp_expr fmt value;
    fprintf fmt "in _| ";
  | Epipelet (id1, value1, id2, value2) -> 
    fprintf fmt "\n(pipelet) %s = " id1.id;
    pp_expr fmt value1;
    fprintf fmt "in | %s = " id2.id;
    pp_expr fmt value2;
    fprintf fmt "in "*)
and pp_def fmt def =
  let (id, param_list, fun_type, special_op_opt, expr_list) = def in
  fprintf fmt "\n\n(fun) id: %s, type: %a, %a (def.id_list): " id.id pp_type_option fun_type pp_special_op special_op_opt;
  
  List.iter (
    fun (ident, bip_type_opt, special_op_opt) ->
      fprintf fmt "%s (%a, %a), " 
      ident.id pp_type_option bip_type_opt pp_special_op special_op_opt
  ) param_list;

  List.iter (fun expr -> pp_expr fmt expr) expr_list
and pp_oexpr fmt (oexpr : Ast_ml.oexpr) (depth : int) (not_last_elem : bool) = 
  (* if not not_last_elem then fprintf fmt "\n%s" (indent depth) else (); *)
  let last_elem_str = if not_last_elem then "" else "\n" ^ indent depth in
  if not_last_elem then fprintf fmt " (NOT LAST) " else fprintf fmt " (LAST) ";
  match oexpr with
  | Onone -> fprintf fmt "\nSOMETHING WENT WRONG!\n"

  | Oident id -> fprintf fmt "%s%s" last_elem_str id.id

  | Ocst c -> fprintf fmt "%s%s" last_elem_str (get_const_str c)

  | Ounop (op, e) -> 
    fprintf fmt "%s" last_elem_str;
    fprintf fmt "%s" (get_unop_str op);
    pp_oexpr fmt e depth not_last_elem

  | Obinop (op, e1, e2) -> 
    fprintf fmt "%s" last_elem_str;
    pp_oexpr fmt e1 depth false;
    fprintf fmt " %s " (get_binop_str op);
    pp_oexpr fmt e2 depth not_last_elem

  | Olet (id, value, body) -> 
    fprintf fmt "\n%slet %s = " (indent depth) id.id;
    pp_oexpr fmt value depth true;
    fprintf fmt " in";
    pp_oexpr fmt body (depth) true

  | Ofun (id, param_list, fun_type, special_op_opt, oexpr_list) ->
    pp_def_ml fmt (id, param_list, fun_type, special_op_opt, oexpr_list)
    (* TODO add depth *)

  | Oapp (id, oexpr_list) -> 
    fprintf fmt "\n%s%s " (indent depth) id.id;
    List.iter (fun oe -> 
                fprintf fmt "%a " 
                (fun fmt _ -> pp_oexpr fmt oe depth true)
                oe) oexpr_list
  
  | Oif (cnd_l, cnd_r, s1, s2) -> 
    let indentation = (indent depth) in
    ( match cnd_r with 
      | Onone -> fprintf fmt "%sif %a\n%sthen " 
                 indentation 
                 (fun fmt _ -> pp_oexpr fmt cnd_l (depth+1) false) cnd_l
                 indentation

      | _ -> fprintf fmt "\n%sassert ( (%a) = (%a) );\n%sif %a\n%sthen "
              indentation
              (fun fmt _ -> pp_oexpr fmt cnd_l depth false) cnd_l
              (fun fmt _ -> pp_oexpr fmt cnd_r depth false) cnd_r
              indentation
              (fun fmt _ -> pp_oexpr fmt cnd_l (depth+1) false) cnd_l
              indentation
    ); 

    let len1 = List.length s1 in
    let len2 = List.length s2 in
    List.iteri (fun idx oe -> let not_last_elem = (idx < len1 - 1) in
                              pp_oexpr fmt oe (depth+1) not_last_elem) s1;
    fprintf fmt "\n%selse " indentation;
    List.iteri (fun idx oe -> let not_last_elem = (idx < len2 - 1) in
                              pp_oexpr fmt oe (depth+1) not_last_elem) s2

  | Ofor (id, value, e_to, body) -> 
    let indentation = (indent depth) in

    fprintf fmt "\n%sfor %s = %a to %a do\n"
      indentation
      id.id
      (fun fmt _ -> pp_oexpr fmt value depth false) value
      (fun fmt _ -> pp_oexpr fmt e_to depth false) e_to; 

    let len = List.length body in
    List.iteri (fun idx oe -> let not_last_elem = (idx < len - 1) in
                              pp_oexpr fmt oe (depth+1) not_last_elem) body;

    if not_last_elem
    then fprintf fmt "\n%sdone;\n" indentation
    else fprintf fmt "\n%sdone\n" indentation

  | Owhile (cnd_l, cnd_r, body) -> 
    let indentation = (indent depth) in

    ( match cnd_r with
      | Onone -> fprintf fmt "\n%swhile %a do\n" 
                  indentation
                  (fun fmt _ -> pp_oexpr fmt cnd_l depth false) cnd_l;

      | _ -> fprintf fmt "\n%swhile %a do\n%s(*@@ invariant %a = %a *)"
              indentation
              (fun fmt _ -> pp_oexpr fmt cnd_l depth false) cnd_l
              (indent (depth+1))
              (fun fmt _ -> pp_oexpr fmt cnd_l depth false) cnd_l
              (fun fmt _ -> pp_oexpr fmt cnd_r depth false) cnd_r
    );
    
    let len = List.length body in
    List.iteri (fun idx oe -> let not_last_elem = (idx < len - 1) in
                              pp_oexpr fmt oe (depth+1) not_last_elem) body;
    
    if not_last_elem
    then fprintf fmt "\n%sdone;\n" indentation
    else fprintf fmt "\n%sdone\n" indentation

  | Oassign (id1, id2, e1, e2) ->
    let indentation = (indent depth) in
    let semicolon_str = if not_last_elem then ";" else "" in
    ( match e2 with
      | Onone -> fprintf fmt "\n%s%s := %a%s"
                  indentation
                  id1.id
                  (fun fmt _ -> pp_oexpr fmt e1 depth true) e1
                  semicolon_str

      | _ -> fprintf fmt "\n%s%s := %a;\n%s%s := %a%s"
              indentation
              id1.id
              (fun fmt _ -> pp_oexpr fmt e1 depth true) e1
              indentation
              id2.id
              (fun fmt _ -> pp_oexpr fmt e2 depth true) e2
              semicolon_str
    ) 

  | Oseq (e1, e2) -> 
    ( match e1 with 
      (* case where there are assigns on both sides of a pipe but the left-hand identifiers are different *)
      | Oassign (id1, id2, oe1, oe2) -> pp_oexpr fmt e1 depth not_last_elem; pp_oexpr fmt e2 depth not_last_elem
      | _ -> fprintf fmt "\n%s(%a, %a)"
              (indent depth)
              (fun fmt _ -> pp_oexpr fmt e1 depth false) e1
              (fun fmt _ -> pp_oexpr fmt e2 depth false) e2
    )

and pp_def_ml fmt (def: Ast_ml.odef) =
  let (id, param_list, fun_type, ret_pair, oexpr_list) = def in
  let fun_type_str = get_type_str fun_type in

  fprintf fmt "let %s" id.id;
  
  List.iter (
    fun (ident, param_type, special_op_opt) ->
      let param_type_str = get_type_str param_type in

      match special_op_opt with 
      | None -> (
        if param_type_str = "" 
        then fprintf fmt " (%s)" ident.id
        else fprintf fmt " (%s : %s)" ident.id param_type_str )
      | _ -> (
        let id1 = ident.id ^ "_l" in
        let id2 = ident.id ^ "_r" in

        if param_type_str = "" 
        then fprintf fmt " (%s, %s)" id1 id2
        else fprintf fmt " (%s : %s) (%s : %s)" id1 param_type_str id2 param_type_str ) 
  ) param_list;

  if fun_type_str = "" then (
    fprintf fmt " ="
  ) else (
    if ret_pair
    then fprintf fmt " : %s * %s =" fun_type_str fun_type_str
    else fprintf fmt " : %s =" fun_type_str
  );

  let len = List.length oexpr_list in
  List.iteri (fun idx oe -> let not_last_elem = (idx < len - 1) in
                            pp_oexpr fmt oe 1 not_last_elem) oexpr_list;
  fprintf fmt "\n\n"
  

let pp_file fmt (file : Ast_bip.file) =
  fprintf fmt "\n\nParser output:"(*;
  List.iter (pp_def fmt) file*)

let pp_ast ast =
  eprintf "@[%a@]@." pp_file ast


let pp_file_ml fmt (file : Ast_ml.ofile) =
  fprintf fmt "\n\nOCaml code:\n\n";
  List.iter (pp_def_ml fmt) file

let bip_to_ml_file (file : Ast_bip.file) : Ast_ml.ofile =
  List.map bip_to_ml_def file

let pp_ast_to_ml (file : Ast_bip.file) =
  eprintf "@[%a@]@." pp_file_ml (bip_to_ml_file file)


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
