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



let get_const_str (const : Ast_core.constant) = 
  match const with
  | Cint  i -> string_of_int i
  | Cbool b -> string_of_bool b
  | Cstring str -> str
  | Cnone -> "Cnone"
  | Cunit -> "()"

let get_unop_str (unop : Ast_core.unop) =
  match unop with
    | Uneg -> "-"
    | Unot -> "not ("
    | Uref -> "ref ("
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
    | Band -> "&&" 
    | Bor -> "||" 
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

let pp_spec_opt spec_opt =
  match spec_opt with 
  | None -> ""
  | Some spec -> spec.text 

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
      | Cunit -> "Cunit"
  in 
    fprintf fmt "%s (constant) " s

let indent depth =
  String.make (depth * 2) ' '

let rec skip s i len =
  if i < len then
    match s.[i] with
    | ' ' | '\t' -> skip s (i+1) len
    | _ -> i
  else
    len

let trim_leading s =
  let len = String.length s in
  let i = skip s 0 len in
  if i = 0 then s 
  else String.sub s i (len - i)

let indent_spec depth (spec_str : string) = 
  if spec_str = "" then "" 
  else
    let lines = String.split_on_char '\n' spec_str in
    match lines with
    | [] -> spec_str
    | _ -> 
      let prefix_str = indent (depth + 3) in
      String.concat "\n" (List.map (fun line -> prefix_str ^ trim_leading line) lines)

let rec get_oexpr_str (oexpr : Ast_ml.oexpr) : string = 
  match oexpr with
  | Onone -> "\nSOMETHING WENT WRONG!\n"

  | Oident id -> id.id

  | Ocst c -> get_const_str c

  | Ounop (op, e) -> 
    let operator_str = (get_unop_str op) in
    let final_par = 
      if operator_str = "ref (" || operator_str = "not (" then ")" else "" in
    operator_str ^ (get_oexpr_str e) ^ final_par

  | Obinop (op, e1, e2) -> 
    (get_oexpr_str e1) ^ " " ^ (get_binop_str op) ^ " " ^ (get_oexpr_str e2)

  | _ -> "\nREST TODO\n"

  (*| Olet (id, value, body) -> 
    fprintf fmt "\n%slet %s = " (indent depth) id.id;
    pp_oexpr fmt value depth true;
    fprintf fmt " in";
    pp_oexpr fmt body depth not_last_elem

  | Ofun (id, param_list, fun_type, special_op_opt, oexpr_list, spec_opt) ->
    pp_def_ml fmt (id, param_list, fun_type, special_op_opt, oexpr_list, spec_opt)
    (* TODO add depth *)

  | Oapp (id, oexpr_list) -> 
    fprintf fmt "%s%s" last_elem_str id.id;
    List.iter (fun oe -> 
                fprintf fmt " (%a)" 
                (fun fmt _ -> pp_oexpr fmt oe depth true)
                oe) oexpr_list
  
  | Oif (cnd_l, cnd_r, s1, s2) -> 
    let indentation = (indent depth) in
    let len1 = List.length s1 in
    let len2 = List.length s2 in

    ( match cnd_r with 
      | Onone -> fprintf fmt "\n%sif %a\n%sthen " 
                 indentation 
                 (fun fmt _ -> pp_oexpr fmt cnd_l (depth+1) true) cnd_l
                 indentation

      | _ -> fprintf fmt "\n%sassert ( (%a) = (%a) );\n%sif %a\n%sthen "
              indentation
              (fun fmt _ -> pp_oexpr fmt cnd_l depth true) cnd_l
              (fun fmt _ -> pp_oexpr fmt cnd_r depth true) cnd_r
              indentation
              (fun fmt _ -> pp_oexpr fmt cnd_l (depth+1) true) cnd_l
              indentation
    );
    
    List.iteri (fun idx oe -> let not_last_elem = (idx < len1 - 1) in
                              pp_oexpr fmt oe (depth+1) not_last_elem) s1;

    fprintf fmt "\n%selse " indentation;

    List.iteri (fun idx oe -> let not_last_elem = (idx < len2 - 1) in
                              pp_oexpr fmt oe (depth+1) not_last_elem) s2

  | Ofor (id, value, e_to, spec_opt, body) -> 
    let indentation = (indent depth) in
    let specification = 
      if (pp_spec_opt spec_opt) = "" then "" 
      else "\n" ^ (indent_spec depth (pp_spec_opt spec_opt)) in

    fprintf fmt "\n\n%sfor %s = %a to %a do%s"
      indentation
      id.id
      (fun fmt _ -> pp_oexpr fmt value depth true) value
      (fun fmt _ -> pp_oexpr fmt e_to depth true) e_to
      specification; 

    let len = List.length body in
    List.iteri (fun idx oe -> let not_last_elem = (idx < len - 1) in
                              pp_oexpr fmt oe (depth+1) not_last_elem) body;

    if not_last_elem
    then fprintf fmt "\n%sdone;\n" indentation
    else fprintf fmt "\n%sdone\n" indentation

  | Owhile (cnd_l, cnd_r, spec_opt, body) -> 
    let indentation = (indent depth) in
    let specification = 
      if (pp_spec_opt spec_opt) = "" then "" 
      else "\n" ^ (indent_spec depth (pp_spec_opt spec_opt)) in

    ( match cnd_r with
      | Onone -> fprintf fmt "\n\n%swhile %a do%s" 
                  indentation
                  (fun fmt _ -> pp_oexpr fmt cnd_l depth true) cnd_l
                  specification

      | _ -> fprintf fmt "\n\n%swhile %a do\n%s(*@@ invariant (%a) <-> (%a)%s*)"
              indentation
              (fun fmt _ -> pp_oexpr fmt cnd_l depth true) cnd_l
              (indent (depth+1))
              (fun fmt _ -> pp_oexpr fmt cnd_l depth true) cnd_l
              (fun fmt _ -> pp_oexpr fmt cnd_r depth true) cnd_r
              specification
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
      (* case where there are assigns on both sides of a pipe
         but the left-hand identifiers are different *)
      | Oassign (id1, id2, oe1, oe2) -> 
        pp_oexpr fmt e1 depth not_last_elem;
        pp_oexpr fmt e2 depth not_last_elem

      | _ -> fprintf fmt "\n%s(%a, %a)"
              (indent depth)
              (fun fmt _ -> pp_oexpr fmt e1 depth true) e1
              (fun fmt _ -> pp_oexpr fmt e2 depth true) e2
    )*)

let rec bip_to_ml_def (def: Ast_bip.def) : Ast_ml.odef =
  let (ident, param_list, bto, special_op_opt, body, spec_op) = def in
    (ident, param_list, bto, special_op_opt <> None,
    List.map (fun e -> bip_to_ml e None) body, spec_op)
and bip_to_ml (e: Ast_bip.expr) (id_side: side option) 
                                (gen_side : side option) : Ast_ml.oexpr =
  match e with  

  | Eident ident -> (
    match id_side with
    | None -> Oident ident
    | Some Left -> Oident ({ ident with id = ident.id ^ "_l" })
    | Some Right -> Oident ({ ident with id = ident.id ^ "_r" }))

  | Ecst c -> Ocst c

  | Eunop (op, e) -> Ounop (op, bip_to_ml e id_side)

  | Ebinop (op, e1, e2) -> 
    Obinop (op, (bip_to_ml e1 id_side), (bip_to_ml e2 id_side))

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

  | Eletpipe (id1, val1, id2, val2, body) -> 
    let ident_l = { id1 with id = id1.id ^ "_l"} in
    let ident_r = { id2 with id = id2.id ^ "_r"} in
    let oe1 = bip_to_ml val1 (Some Left) in
    let oe2 = bip_to_ml val2 (Some Right) in
    let oe_body = bip_to_ml body None in
    Olet (ident_l, oe1, Olet(ident_r, oe2, oe_body))

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

  | Efor (ident, e_val, e_to, spec, el_body) ->
    let oe_val = bip_to_ml e_val None 
    and oe_to = bip_to_ml e_to None 
    and oel_body = List.map (fun e -> bip_to_ml e None) el_body in
    Ofor (ident, oe_val, oe_to, spec, oel_body)

  | Ewhile (Efloor e_cnd, spec, el_body) ->
    let oe_cnd_l = bip_to_ml e_cnd (Some Left)
    and oe_cnd_r = bip_to_ml e_cnd (Some Right)
    and oel_body = List.map (fun e -> bip_to_ml e None) el_body in
    Owhile (oe_cnd_l, oe_cnd_r, spec, oel_body)

  | Ewhile (Epipe (e_cnd1, e_cnd2), spec, el_body) ->
    let oe_cnd_l = bip_to_ml e_cnd1 (Some Left)
    and oe_cnd_r = bip_to_ml e_cnd2 (Some Right)
    and oel_body = List.map (fun e -> bip_to_ml e None) el_body in
    Owhile (oe_cnd_l, oe_cnd_r, spec, oel_body)

  | Ewhile (e_cnd, spec, el_body) ->
    let oe_cnd = bip_to_ml e_cnd None
    and oel_body = List.map (fun e -> bip_to_ml e None) el_body in
    Owhile (oe_cnd, Onone, spec, oel_body)

  | Ewhilecnd (cnd1, cnd2, ag1, ag2, spec, body) ->
    let el = bip_to_ml cnd1 (Some Left) in
    let er = bip_to_ml cnd2 (Some Right) in 
    let fp = bip_to_ml ag1 (Some Left) in 
    let fp' = bip_to_ml ag2 (Some Right) in

    let el_str = get_oexpr_str el in
    let er_str = get_oexpr_str er in
    let fp_str = get_oexpr_str fp in
    let fp'_str = get_oexpr_str fp' in

    (*Printf.printf "\n\nel_str: %s\n" el_str;
    Printf.printf "er_str: %s\n" er_str;
    Printf.printf "fp_str: %s\n" fp_str;
    Printf.printf "fp'_str: %s\n\n\n" fp'_str;*)

    let a = 
      "(" ^ el_str ^ " && " ^ fp_str ^ ") || (" ^
      "(" ^ er_str ^ " && " ^ fp'_str ^ ") || (" ^
      "(not (" ^ el_str ^ ") && not (" ^ er_str ^ ")) || (" ^
      "(" ^ el_str ^ " && " ^ er_str ^ ")" in

    let complete_spec = 
      match spec with 
      | None -> a 
      | Some sp -> sp.text ^ "&& (" ^ a ^ ")" in

    let final_spec_text = "(*@" ^ complete_spec ^ " *)" in

    let final_spec = 
      Some ({ loc = (Lexing.dummy_pos, Lexing.dummy_pos);
              text = final_spec_text}) in

    let body_l = List.map (fun e -> bip_to_ml e (Some Left)) body in
    let body_r = List.map (fun e -> bip_to_ml e (Some Right)) body in
    let body_both = List.map (fun e -> bip_to_ml e None) body in

    (* TODO: 
      Generate only left and neutral instructions for body_l, 
      similar for body_r and normal generation for body_both.

      Why is assert for Oif being generated?
      Because the ifs are not the ifs below, but a separate Eif -> Oif translation,
      which translates all the body for both sides.
      The ifs below are correctly translated and printed.
        
      Solution: 
      Add a gen_side parameter to bip_to_ml function that says which side to generate
      instructions when a pipe or a floor appear.
      *)

    Owhile (Obinop (Bor, el, er), Onone, final_spec,
      [Oif (Obinop (Band, el, fp), Onone, body_l, 
        [Oif (Obinop (Band, er, fp'), Onone, body_r, body_both)])])

  | Eassign (ident, Efloor e) ->
    let ident_l = { ident with id = ident.id ^ "_l"} in
    let ident_r = { ident with id = ident.id ^ "_r"} in
    Oassign (ident_l, ident_r, bip_to_ml e (Some Left), bip_to_ml e (Some Right))

  | Eassign (ident, Epipe (e1, e2)) -> 
    let ident_l = { ident with id = ident.id ^ "_l"} in
    let ident_r = { ident with id = ident.id ^ "_r"} in
    Oassign (ident_l, ident_r, bip_to_ml e1 (Some Left), bip_to_ml e2 (Some Right)) 

  | Eassign (ident, e) ->
    ( match id_side with 
      | None -> Oassign (ident, ident, bip_to_ml e id_side, Onone)
      | Some Left -> 
        let ident_l = { ident with id = ident.id ^ "_l"} in
        Oassign (ident_l, ident_l, bip_to_ml e id_side, Onone)
      | Some Right -> 
        let ident_r = { ident with id = ident.id ^ "_r"} in
        Oassign (ident_r, ident_r, bip_to_ml e id_side, Onone) )
     
  | Efloor e -> bip_to_ml (Epipe (e, e)) None 

  | Epipe (e1, e2) -> Oseq(bip_to_ml e1 (Some Left), bip_to_ml e2 (Some Right))

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
  | Eletpipe (id1, value1, id2, value2, body) -> 
    fprintf fmt "todo" 
  | Efun (id, param_list, fun_type, special_op_opt, expr_list, spec_opt) ->
    pp_def fmt (id, param_list, fun_type, special_op_opt, expr_list, spec_opt)
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
  | Efor (id, value, e_to, spec_opt, body) -> 
    fprintf fmt "\n(for) id = %s, val = " id.id; 
    pp_expr fmt value;     
    fprintf fmt "to ";         
    pp_expr fmt e_to; 
    fprintf fmt "do"; 
    fprintf fmt "%s" (pp_spec_opt spec_opt);
    List.iter (fun expr -> pp_expr fmt expr) body;
    fprintf fmt "done";
  | Ewhile (cnd, spec_opt, body) -> 
    fprintf fmt "\n(while) "; 
    pp_expr fmt cnd; 
    fprintf fmt "do"; 
    fprintf fmt "%s" (pp_spec_opt spec_opt);
    List.iter (fun expr -> pp_expr fmt expr) body;
    fprintf fmt "done";
  | Ewhilecnd (cnd1, cnd2, ag1, ag2, spec, body) ->
    fprintf fmt "todo"
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
and pp_def fmt def =
  let (id, param_list, fun_type, special_op_opt, expr_list, spec) = def in
  fprintf fmt "\n\n(fun) id: %s, type: %a, %a (def.id_list): " 
  id.id pp_type_option fun_type pp_special_op special_op_opt;
  
  List.iter (
    fun (ident, bip_type_opt, special_op_opt) ->
      fprintf fmt "%s (%a, %a), " 
      ident.id pp_type_option bip_type_opt pp_special_op special_op_opt
  ) param_list;

  List.iter (fun expr -> pp_expr fmt expr) expr_list;
  fprintf fmt "%s" spec.text

and pp_oexpr fmt (oexpr : Ast_ml.oexpr) (depth : int) (not_last_elem : bool) = 
  let last_elem_str = if not_last_elem then "" else "\n" ^ indent depth in
  
  match oexpr with
  | Onone -> fprintf fmt "\nSOMETHING WENT WRONG!\n"

  | Oident id -> fprintf fmt "%s%s" last_elem_str id.id

  | Ocst c -> fprintf fmt "%s%s" last_elem_str (get_const_str c)

  | Ounop (op, e) -> 
    let operator_str = (get_unop_str op) in
    fprintf fmt "%s%s" last_elem_str operator_str;

    ( if not_last_elem 
      then pp_oexpr fmt e depth not_last_elem
      else pp_oexpr fmt e depth true );

    if operator_str = "ref (" || operator_str = "not (" then fprintf fmt ")" else ()

  | Obinop (op, e1, e2) -> 
    fprintf fmt "%s" last_elem_str;
    pp_oexpr fmt e1 depth true;
    fprintf fmt " %s " (get_binop_str op);
    pp_oexpr fmt e2 depth true

  | Olet (id, value, body) -> 
    fprintf fmt "\n%slet %s = " (indent depth) id.id;
    pp_oexpr fmt value depth true;
    fprintf fmt " in";
    pp_oexpr fmt body depth not_last_elem

  | Ofun (id, param_list, fun_type, special_op_opt, oexpr_list, spec_opt) ->
    pp_def_ml fmt (id, param_list, fun_type, special_op_opt, oexpr_list, spec_opt)
    (* TODO add depth *)

  | Oapp (id, oexpr_list) -> 
    fprintf fmt "%s%s" last_elem_str id.id;
    List.iter (fun oe -> 
                fprintf fmt " (%a)" 
                (fun fmt _ -> pp_oexpr fmt oe depth true)
                oe) oexpr_list
  
  | Oif (cnd_l, cnd_r, s1, s2) -> 
    let indentation = (indent depth) in
    let len1 = List.length s1 in
    let len2 = List.length s2 in

    Printf.printf "\n\ncnd_r: %b\n" (cnd_r = Onone);

    ( match cnd_r with 
      | Onone -> fprintf fmt "\n%sif %a\n%sthen begin " 
                 indentation 
                 (fun fmt _ -> pp_oexpr fmt cnd_l (depth+1) true) cnd_l
                 indentation

      | _ -> fprintf fmt "\n%sassert ( (%a) = (%a) );\n%sif %a\n%sthen begin "
              indentation
              (fun fmt _ -> pp_oexpr fmt cnd_l depth true) cnd_l
              (fun fmt _ -> pp_oexpr fmt cnd_r depth true) cnd_r
              indentation
              (fun fmt _ -> pp_oexpr fmt cnd_l (depth+1) true) cnd_l
              indentation
    );
    
    List.iteri (fun idx oe -> let not_last_elem = (idx < len1 - 1) in
                              pp_oexpr fmt oe (depth+1) not_last_elem) s1;

    fprintf fmt "\n%send else begin " indentation;

    List.iteri (fun idx oe -> let not_last_elem = (idx < len2 - 1) in
                              pp_oexpr fmt oe (depth+1) not_last_elem) s2;

    if not_last_elem
    then fprintf fmt "\n%send;" indentation
    else fprintf fmt "\n%send" indentation

  | Ofor (id, value, e_to, spec_opt, body) -> 
    let indentation = (indent depth) in
    let specification = 
      if (pp_spec_opt spec_opt) = "" then "" 
      else "\n" ^ (indent_spec depth (pp_spec_opt spec_opt)) in

    fprintf fmt "\n\n%sfor %s = %a to %a do%s"
      indentation
      id.id
      (fun fmt _ -> pp_oexpr fmt value depth true) value
      (fun fmt _ -> pp_oexpr fmt e_to depth true) e_to
      specification; 

    let len = List.length body in
    List.iteri (fun idx oe -> let not_last_elem = (idx < len - 1) in
                              pp_oexpr fmt oe (depth+1) not_last_elem) body;

    if not_last_elem
    then fprintf fmt "\n%sdone;\n" indentation
    else fprintf fmt "\n%sdone\n" indentation

  | Owhile (cnd_l, cnd_r, spec_opt, body) -> 
    let indentation = (indent depth) in
    let specification = 
      if (pp_spec_opt spec_opt) = "" then "" 
      else "\n" ^ (indent_spec depth (pp_spec_opt spec_opt)) in

    ( match cnd_r with
      | Onone -> fprintf fmt "\n\n%swhile %a do%s" 
                  indentation
                  (fun fmt _ -> pp_oexpr fmt cnd_l depth true) cnd_l
                  specification

      | _ -> fprintf fmt "\n\n%swhile %a do\n%s(*@@ invariant (%a) <-> (%a)%s*)"
              indentation
              (fun fmt _ -> pp_oexpr fmt cnd_l depth true) cnd_l
              (indent (depth+1))
              (fun fmt _ -> pp_oexpr fmt cnd_l depth true) cnd_l
              (fun fmt _ -> pp_oexpr fmt cnd_r depth true) cnd_r
              specification
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
      (* case where there are assigns on both sides of a pipe
         but the left-hand identifiers are different *)
      | Oassign (id1, id2, oe1, oe2) -> 
        pp_oexpr fmt e1 depth not_last_elem;
        pp_oexpr fmt e2 depth not_last_elem

      | _ -> fprintf fmt "\n%s(%a, %a)"
              (indent depth)
              (fun fmt _ -> pp_oexpr fmt e1 depth true) e1
              (fun fmt _ -> pp_oexpr fmt e2 depth true) e2
    )

and pp_def_ml fmt (def: Ast_ml.odef) =
  let (id, param_list, fun_type, ret_pair, oexpr_list, spec) = def in
  let fun_type_str = get_type_str fun_type in

  fprintf fmt "let %s" id.id;

  if param_list = [] then fprintf fmt " ()" 
  else
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

  let pair_ret_ensures = 
    if ret_pair 
    then "\n    ensures match result with (l_res, r_res) -> l_res = r_res"
    else "" in

  let specification = if spec.text = "" then ""
                      else "\n(*@" ^ spec.text ^ pair_ret_ensures ^ " *)" in

  fprintf fmt "%s\n\n" specification
  

let pp_spec_ml fmt (sp: spec) =
  fprintf fmt "(*@%s*)\n\n" sp.text

let pp_file fmt (file : Ast_bip.file) =
  fprintf fmt "" (*"\n\nParser output:";
  List.iter (pp_def fmt) file*)

let pp_ast ast =
  eprintf "@[%a@]@." pp_file ast


let pp_file_ml fmt (file : Ast_ml.ofile) =
  (*fprintf fmt "\n\nOCaml code:\n\n";*)
  List.iter (fun odecl ->
    match odecl with 
    | Odef odef -> pp_def_ml fmt odef
    | Ospec ospec -> pp_spec_ml fmt ospec
  ) file

let write_ml_to_file (filename : string) (file : Ast_ml.ofile) : unit =
  let oc = open_out filename in
  let fmt = formatter_of_out_channel oc in
  pp_file_ml fmt file;
  pp_print_flush fmt ();
  close_out oc

let bip_to_ml_file (file : Ast_bip.file) : Ast_ml.ofile =
  List.map (fun decl -> 
    match decl with 
    | Edef def -> Odef (bip_to_ml_def def)
    | Espec spec -> (Ospec spec)
  ) file

let pp_ml (ofile : Ast_ml.ofile) =
  eprintf "@[%a@]@." pp_file_ml ofile


let () =
  let c = open_in file in
  let lb = Lexing.from_channel c in
  try
    let f = Parser.file Lexer.next_token lb in
    close_in c;

    pp_ast f; (* print ast *)

    let ofile = bip_to_ml_file f in
    pp_ml ofile; (* print OCaml code to terminal *)
    write_ml_to_file "test.ml" ofile; (* print OCaml code to file *)

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
