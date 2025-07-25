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

let indent_spaces = 2
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
  | Cstring str -> "\"" ^ str ^ "\""
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
    | STRING -> "string"
    | NONE -> ""


let pp_spec_opt spec_opt =
  match spec_opt with 
  | None -> ""
  | Some spec -> spec.text 

let get_pattern_str (ptrn: pattern) : string =
  match ptrn with
  | Pwildcard -> "_"
  | Pconst c -> get_const_str c
  | Pident ident -> ident.id

let indent depth =
  String.make (depth * indent_spaces) ' '

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

let indent_spec depth spec_str first_line_diff =
  if spec_str = "" then ""
  else
    let lines = String.split_on_char '\n' spec_str in
    match lines with
    | [] -> spec_str
    | first :: rest ->
      let prefix_first = indent (depth + 
        (if first_line_diff then 3 else 5)) in
      let prefix_rest  = indent (depth + 5) in
      let head = prefix_first ^ trim_leading first in
      let tail = List.map (fun line -> prefix_rest ^ trim_leading line) rest in
      String.concat "\n" (head :: tail)


(* There will be problems with mod in specs because of Cameleer needing it prefix. 
   This does not cover more complex cases where the expressions before or after
   mod have spaces, such as "2 * w mod n". This translates incorrectly to "2 * mod w n".

   Anyways, the regexp does 3 things:
     1.  \\([^ ]+\\)   – capture “anything but spaces” as group 1
     2.   mod
     3.  \\([^ ]+\\)   – capture the second expression as group 2   
*)
let swap_mod_order s =
  let re = Str.regexp "\\([^ ]+\\) mod \\([^ ]+\\)" in
  Str.global_replace re "mod \\1 \\2" s

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

  | _ -> "\nREST_NEED_TO_COMPLETE\n"


let add_side_to_id ident side = 
  match side with 
  | None -> ident
  | Some Left -> { ident with id = ident.id ^ "_l"}
  | Some Right -> { ident with id = ident.id ^ "_r"}


let rec bip_to_ml_fun (ident, is_rec, param_list, bto, special_op_opt, body, spec_op, after) =
    (ident, is_rec, param_list, bto, special_op_opt <> None,
    List.map (fun e -> bip_to_ml e None None) body, spec_op, bip_to_ml after None None)

and bip_to_ml_def (def: Ast_bip.def) : Ast_ml.odef =
  let (ident, is_rec, param_list, bto, special_op_opt, body, spec_op) = def in
    (ident, is_rec, param_list, bto, special_op_opt <> None,
    List.map (fun e -> bip_to_ml e None None) body, spec_op)

and bip_to_ml_case (case: Ast_bip.case) : Ast_ml.ocase = 
  let (ptrn, e) = case in
  (ptrn, bip_to_ml e None None)

and bip_to_ml (e: Ast_bip.expr) (id_side: side option) 
                                (gen_side : side option) : Ast_ml.oexpr =

  match e with  

  | Eident ident -> Oident (add_side_to_id ident id_side)

  | Ecst c -> Ocst c

  | Eunop (op, e) -> Ounop (op, bip_to_ml e id_side gen_side)

  | Ebinop (op, e1, e2) -> 
    Obinop (op, (bip_to_ml e1 id_side gen_side), (bip_to_ml e2 id_side gen_side))

  | Elet (ident, Efloor e, body) ->
    ( match gen_side with
      | None ->
        let ident_l = { ident with id = ident.id ^ "_l"} 
        and ident_r = { ident with id = ident.id ^ "_r"}
        and oe1_l = bip_to_ml e (Some Left) gen_side
        and oe1_r = bip_to_ml e (Some Right) gen_side
        and oe2 = bip_to_ml body None gen_side in
        Olet (ident_l, oe1_l, Olet (ident_r, oe1_r, oe2))

      | Some Left -> 
        let ident_l = { ident with id = ident.id ^ "_l"}
        and oe_l = bip_to_ml e (Some Left) (Some Left)
        and oebody = bip_to_ml body None gen_side in
        Olet (ident_l, oe_l, oebody)

      | Some Right ->
        let ident_r = { ident with id = ident.id ^ "_r"}
        and oe_r = bip_to_ml e (Some Right) (Some Right)
        and oebody = bip_to_ml body None gen_side in
        Olet (ident_r, oe_r, oebody)
    )

  | Elet (ident, Epipe (e1, e2), e_body) ->
    ( match gen_side with
      | None ->
        let ident_l = { ident with id = ident.id ^ "_l"} in
        let ident_r = { ident with id = ident.id ^ "_r"} in
        let oe1 = bip_to_ml e1 (Some Left) gen_side in
        let oe2 = bip_to_ml e2 (Some Right) gen_side in
        let oe_body = bip_to_ml e_body None gen_side in
        Olet (ident_l, oe1, Olet (ident_r, oe2, oe_body))
      
      | Some Left -> 
        let ident_l = { ident with id = ident.id ^ "_l"} in
        let oe1 = bip_to_ml e1 (Some Left) (Some Left) in
        let oe_body = bip_to_ml e_body None (Some Left) in
        Olet (ident_l, oe1, oe_body)

      | Some Right ->
        let ident_r = { ident with id = ident.id ^ "_r"} in
        let oe2 = bip_to_ml e1 (Some Right) (Some Right) in
        let oe_body = bip_to_ml e_body None (Some Right) in
        Olet (ident_r, oe2, oe_body)
    )

  | Elet (x, e1, e2) -> 
    Olet (x, bip_to_ml e1 None gen_side, bip_to_ml e2 None gen_side)

  | Eletpipe (id1, val1, id2, val2, body) -> 
    ( match gen_side with
      | None ->
        let ident_l = { id1 with id = id1.id ^ "_l"} in
        let ident_r = { id2 with id = id2.id ^ "_r"} in
        let oe1 = bip_to_ml val1 (Some Left) gen_side in
        let oe2 = bip_to_ml val2 (Some Right) gen_side in
        let oe_body = bip_to_ml body None gen_side in
        Olet (ident_l, oe1, Olet(ident_r, oe2, oe_body))

      | Some Left -> 
        let ident_l = { id1 with id = id1.id ^ "_l"} in
        let oe1 = bip_to_ml val1 (Some Left) (Some Left) in
        let oe_body = bip_to_ml body None (Some Left) in
        Olet (ident_l, oe1, oe_body)

      | Some Right ->
        let ident_r = { id1 with id = id2.id ^ "_r"} in
        let oe2 = bip_to_ml val1 (Some Right) (Some Right) in
        let oe_body = bip_to_ml body None (Some Right) in
        Olet (ident_r, oe2, oe_body)
    )

  | Efun (id, is_rec, param_list, fun_type, special_op_opt, expr_list, spec_opt, after) ->
    let (id, is_rec, param_list, fun_type, special_op_opt, oexpr_list, spec_opt, after) =
      (bip_to_ml_fun (id, is_rec, param_list, fun_type, special_op_opt, expr_list, spec_opt, after)) in
    Ofun (id, is_rec, param_list, fun_type, special_op_opt, oexpr_list, spec_opt, after)

  | Eapp (ident, expr_list) -> 
    Oapp (ident, (List.map (fun e -> bip_to_ml e None gen_side) expr_list))

  | Eif (Efloor e_cnd, el_then, el_else) ->
    ( match gen_side with 
      | None ->
        let oe_cnd_l = bip_to_ml e_cnd (Some Left) gen_side
        and oe_cnd_r = bip_to_ml e_cnd (Some Right) gen_side
        and oel_then = List.map (fun e -> bip_to_ml e None gen_side) el_then
        and oel_else = List.map (fun e -> bip_to_ml e None gen_side) el_else in
        Oif (oe_cnd_l, oe_cnd_r, oel_then, oel_else)

      | Some Left ->
        let oe_cnd_l = bip_to_ml e_cnd (Some Left) (Some Left)
        and oel_then = List.map (fun e -> bip_to_ml e None (Some Left)) el_then
        and oel_else = List.map (fun e -> bip_to_ml e None (Some Left)) el_else in
        Oif (oe_cnd_l, Onone, oel_then, oel_else)

      | Some Right ->
        let oe_cnd_r = bip_to_ml e_cnd (Some Right) (Some Right)
        and oel_then = List.map (fun e -> bip_to_ml e None (Some Right)) el_then
        and oel_else = List.map (fun e -> bip_to_ml e None (Some Right)) el_else in
        Oif (oe_cnd_r, Onone, oel_then, oel_else)
    )
    
  | Eif (Epipe (e_cnd1, e_cnd2), el_then, el_else) ->
    ( match gen_side with
      | None ->
        let oe_cnd_l = bip_to_ml e_cnd1 (Some Left) gen_side
        and oe_cnd_r = bip_to_ml e_cnd2 (Some Right) gen_side
        and oel_then = List.map (fun e -> bip_to_ml e None gen_side) el_then
        and oel_else = List.map (fun e -> bip_to_ml e None gen_side) el_else in
        Oif (oe_cnd_l, oe_cnd_r, oel_then, oel_else)

      | Some Left ->
        let oe_cnd_l = bip_to_ml e_cnd1 (Some Left) (Some Left)
        and oel_then = List.map (fun e -> bip_to_ml e None (Some Left)) el_then
        and oel_else = List.map (fun e -> bip_to_ml e None (Some Left)) el_else in
        Oif (oe_cnd_l, Onone, oel_then, oel_else)

      | Some Right ->
        let oe_cnd_r = bip_to_ml e_cnd2 (Some Right) (Some Right)
        and oel_then = List.map (fun e -> bip_to_ml e None (Some Right)) el_then
        and oel_else = List.map (fun e -> bip_to_ml e None (Some Right)) el_else in
        Oif (oe_cnd_r, Onone, oel_then, oel_else)
    )

  | Eif (e_cnd, el_then, el_else) ->
    let oe_cnd = bip_to_ml e_cnd None gen_side 
    and oel_then = List.map (fun e -> bip_to_ml e None gen_side) el_then
    and oel_else = List.map (fun e -> bip_to_ml e None gen_side) el_else in
    Oif (oe_cnd, Onone, oel_then, oel_else)

  | Efor (ident, e_val, e_to, spec, el_body) ->
    let oe_val = bip_to_ml e_val None gen_side
    and oe_to = bip_to_ml e_to None gen_side 
    and oel_body = List.map (fun e -> bip_to_ml e None gen_side) el_body in
    Ofor (ident, oe_val, oe_to, spec, oel_body)

  | Ewhile (Efloor e_cnd, spec, el_body) ->
    ( match gen_side with
      | None ->
        let oe_cnd_l = bip_to_ml e_cnd (Some Left) gen_side
        and oe_cnd_r = bip_to_ml e_cnd (Some Right) gen_side
        and oel_body = List.map (fun e -> bip_to_ml e None gen_side) el_body in
        Owhile (oe_cnd_l, oe_cnd_r, spec, oel_body)

      | Some Left ->
        let oe_cnd_l = bip_to_ml e_cnd (Some Left) (Some Left)
        and oel_body = List.map (fun e -> bip_to_ml e None gen_side) el_body in
        Owhile (oe_cnd_l, Onone, spec, oel_body)

      | Some Right ->
        let oe_cnd_r = bip_to_ml e_cnd (Some Right) (Some Right)
        and oel_body = List.map (fun e -> bip_to_ml e None gen_side) el_body in
        Owhile (oe_cnd_r, Onone, spec, oel_body)
    )

  | Ewhile (Epipe (e_cnd1, e_cnd2), spec, el_body) ->
    ( match gen_side with
      | None ->
        let oe_cnd_l = bip_to_ml e_cnd1 (Some Left) gen_side
        and oe_cnd_r = bip_to_ml e_cnd2 (Some Right) gen_side
        and oel_body = List.map (fun e -> bip_to_ml e None gen_side) el_body in
        Owhile (oe_cnd_l, oe_cnd_r, spec, oel_body)

      | Some Left ->
        let oe_cnd_l = bip_to_ml e_cnd1 (Some Left) (Some Left)
        and oel_body = List.map (fun e -> bip_to_ml e None gen_side) el_body in
        Owhile (oe_cnd_l, Onone, spec, oel_body)

      | Some Right ->
        let oe_cnd_r = bip_to_ml e_cnd2 (Some Right) (Some Right)
        and oel_body = List.map (fun e -> bip_to_ml e None gen_side) el_body in
        Owhile (oe_cnd_r, Onone, spec, oel_body)
    )

  | Ewhile (e_cnd, spec, el_body) ->
    let oe_cnd = bip_to_ml e_cnd None gen_side
    and oel_body = List.map (fun e -> bip_to_ml e None gen_side) el_body in
    Owhile (oe_cnd, Onone, spec, oel_body)

  | Ewhilecnd (cnd1, cnd2, ag1, ag2, spec, body) -> 
    let el = bip_to_ml cnd1 (Some Left) None in
    let er = bip_to_ml cnd2 (Some Right) None in 
    let fp = bip_to_ml ag1 (Some Left) None in 
    let fp' = bip_to_ml ag2 (Some Right) None in

    let el_str = get_oexpr_str el in
    let er_str = get_oexpr_str er in
    let fp_str = get_oexpr_str fp in
    let fp'_str = get_oexpr_str fp' in

    let a = 
      "(" ^ el_str ^ " && " ^ fp_str ^ ") || " ^
      "(" ^ er_str ^ " && " ^ fp'_str ^ ") || " ^
      "(not (" ^ el_str ^ ") && not (" ^ er_str ^ ")) || " ^
      "(" ^ el_str ^ " && " ^ er_str ^ ")" in

    let complete_spec = 
      match spec with 
      | None -> a 
      | Some sp -> sp.text ^ "\n invariant " ^ a in

    let final_spec_text = "(*@" ^ complete_spec ^ " *)" in

    let final_spec = 
      Some ({ loc = (Lexing.dummy_pos, Lexing.dummy_pos);
              text = final_spec_text}) in

    let body_l = List.map (fun e -> bip_to_ml e (Some Left) (Some Left)) body in
    let body_r = List.map (fun e -> bip_to_ml e (Some Right) (Some Right)) body in
    let body_both = List.map (fun e -> bip_to_ml e None None) body in

    Owhile (Obinop (Bor, el, er), Onone, final_spec,
      [Oif (Obinop (Band, el, fp), Onone, body_l, 
        [Oif (Obinop (Band, er, fp'), Onone, body_r, body_both)])])

  | Eassign (ident, Efloor e) ->
    ( match gen_side with
      | None ->
        let ident_l = { ident with id = ident.id ^ "_l"} in
        let ident_r = { ident with id = ident.id ^ "_r"} in
        let oe_l = bip_to_ml e (Some Left) gen_side in
        let oe_r = bip_to_ml e (Some Right) gen_side in
        Oassign (ident_l, ident_r, oe_l, oe_r)

      | Some Left ->
        let ident_final = { ident with id = ident.id ^ "_l"} in
        let ident_discard = { ident with id = "NULL!!!"} in
        let oe_l = bip_to_ml e (Some Left) gen_side in
        Oassign (ident_final, ident_discard, oe_l, Onone)

      | Some Right ->
        let ident_final = { ident with id = ident.id ^ "_r"} in
        let ident_discard = { ident with id = "NULL!!!"} in
        let oe_r = bip_to_ml e (Some Right) gen_side in
        Oassign (ident_final, ident_discard, oe_r, Onone)
    )

  | Eassign (ident, Epipe (e1, e2)) -> 
    ( match gen_side with
      | None ->
        let ident_l = { ident with id = ident.id ^ "_l"} in
        let ident_r = { ident with id = ident.id ^ "_r"} in
        let oe_l = bip_to_ml e1 (Some Left) gen_side in
        let oe_r = bip_to_ml e2 (Some Right) gen_side in
        Oassign (ident_l, ident_r, oe_l, oe_r)

      | Some Left ->
        let ident_final = { ident with id = ident.id ^ "_l"} in
        let ident_discard = { ident with id = "NULL!!!"} in
        let oe_l = bip_to_ml e1 (Some Left) gen_side in
        Oassign (ident_final, ident_discard, oe_l, Onone)

      | Some Right ->
        let ident_final = { ident with id = ident.id ^ "_r"} in
        let ident_discard = { ident with id = "NULL!!!"} in
        let oe_r = bip_to_ml e2 (Some Right) gen_side in
        Oassign (ident_final, ident_discard, oe_r, Onone)
    )

  | Eassign (ident, e) ->
    let ident_final = add_side_to_id ident id_side in
    Oassign (ident_final, ident_final, bip_to_ml e id_side gen_side, Onone)

  | Eassert e -> Oassert (bip_to_ml e id_side gen_side)

  | Ematch (ident, cases) ->
    let ident_final = add_side_to_id ident id_side in
    (* rev because of the way it is collected in the parser (case_list rule) *)
    let ocases = List.rev (List.map (fun case -> bip_to_ml_case case) cases) in
    Omatch (ident_final, ocases)
     
  | Efloor e -> bip_to_ml (Epipe (e, e)) None gen_side 
  
  | Epipe (e1, e2) -> 
    Oseq (bip_to_ml e1 (Some Left) gen_side, bip_to_ml e2 (Some Right) gen_side) 


let rec pp_oapp_core fmt oapp depth =
  let (id, oexpr_list) = oapp in
  fprintf fmt "%s" id.id;
  List.iter (fun oe -> 
    fprintf fmt " (%a)" 
    (fun fmt _ -> pp_oexpr fmt oe depth true)
    oe) oexpr_list

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
      else pp_oexpr fmt e depth true 
    );

    if operator_str = "ref (" || operator_str = "not (" 
    then fprintf fmt ")"
    else ()

  | Obinop (op, e1, e2) -> 
    fprintf fmt "%s" last_elem_str;
    pp_oexpr fmt e1 depth true;
    fprintf fmt " %s " (get_binop_str op);
    pp_oexpr fmt e2 depth true

  | Olet (id, value, body) -> 
    fprintf fmt "\n%slet %s = " (indent depth) id.id;

    ( match value with 
      | Oapp (id, oexpr_list) -> pp_oapp_core fmt (id, oexpr_list) depth
      | _ -> pp_oexpr fmt value depth true
    );
    
    fprintf fmt " in";
    pp_oexpr fmt body depth not_last_elem

  | Ofun (id, is_rec, param_list, fun_type, special_op_opt, oexpr_list, spec_opt, after) ->
    let ofun = Ofun (id, is_rec, param_list, fun_type, special_op_opt, oexpr_list, spec_opt, after) in
    pp_fun_ml fmt ofun depth not_last_elem
  
  | Oif (cnd_l, cnd_r, s1, s2) -> 
    let indentation = (indent depth) in
    let len1 = List.length s1 in
    let len2 = List.length s2 in

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
      else "\n" ^ (swap_mod_order (indent_spec depth (pp_spec_opt spec_opt) true)) in

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
    let first_line_diff = cnd_r = Onone in
    let indented_spec = indent_spec (depth-2) (pp_spec_opt spec_opt) first_line_diff in
    let specification = 
      if (pp_spec_opt spec_opt) = "" then "" 
      else "\n" ^ (swap_mod_order indented_spec) in

    ( match cnd_r with
      | Onone -> 
        fprintf fmt "\n\n%swhile %a do%s" 
        indentation
        (fun fmt _ -> pp_oexpr fmt cnd_l depth true) cnd_l
        specification

      | _ -> 
        fprintf fmt "\n\n%swhile %a do\n%s(*@@ invariant (%a) <-> (%a)%s*)"
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

  | Oapp (id, oexpr_list) -> 
    let indentation = (indent depth) in
    let semicolon_str = if not_last_elem then ";" else "" in
    let oapp = (id, oexpr_list) in

    fprintf fmt "\n%s%a%s" 
      indentation 
      (fun fmt _ -> pp_oapp_core fmt oapp depth) oapp
      semicolon_str

  | Oassert (oe) ->
    let indentation = (indent depth) in
    let semicolon_str = if not_last_elem then ";" else "" in

    fprintf fmt "\n%sassert (%a)%s"
      indentation
      (fun fmt _ -> pp_oexpr fmt oe depth true) oe
      semicolon_str

  | Omatch (id, cases) -> 
    let depth = if not_last_elem then (depth + 1) else depth in
    let indentation = (indent depth) in
    let not_last_elem_str = if not_last_elem then "( " else "" in

    fprintf fmt "\n%s%smatch %s with" 
      indentation 
      not_last_elem_str 
      id.id;

    List.iter (fun case -> 
      let (ptrn, oe) = case in
      fprintf fmt "\n%s| %s -> %a"
        indentation
        (get_pattern_str ptrn)
        (fun fmt _ -> pp_oexpr fmt oe (depth + 1) true) oe
    ) cases;
    
     if not_last_elem then fprintf fmt " )" else ();

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

and pp_def_ml_core fmt id is_rec param_list fun_type ret_pair oexpr_list spec depth = 
  let fun_type_str = get_type_str fun_type in
  let is_rec_str = if is_rec then "rec " else "" in
  let inner_fun = if depth = 0 then "" else "\n" in
  let indentation = indent depth in

  fprintf fmt "%s%slet %s%s" inner_fun indentation is_rec_str id.id;

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
                            pp_oexpr fmt oe (depth+1) not_last_elem) oexpr_list;

  let specification = 
    if spec.text = "" then ""
    else "(*@" ^ (swap_mod_order spec.text) ^ "*)" in

  specification

and pp_def_ml fmt (odef: Ast_ml.odef) =
  let (id, is_rec, param_list, fun_type, ret_pair, oexpr_list, spec) = odef in 
  let specification = (pp_def_ml_core fmt id is_rec param_list fun_type ret_pair oexpr_list spec 0) in
  fprintf fmt "\n%s\n\n" specification
  
and pp_fun_ml fmt (oe: Ast_ml.oexpr) depth not_last_elem = 
  match oe with
  | Ofun (id, is_rec, param_list, fun_type, ret_pair, oexpr_list, spec, after) ->
    let specification = (pp_def_ml_core fmt id is_rec param_list fun_type ret_pair oexpr_list spec depth) in
    fprintf fmt "\n%s%s\n%sin\n%s%a" 
      (indent depth)
      specification
      (indent depth)
      (indent (depth+1))
      (fun fmt _ -> pp_oexpr fmt after depth not_last_elem) after

  | _ -> fprintf fmt "\nERROR!\n"


let pp_spec_ml fmt (sp: spec) =
  fprintf fmt "(*@%s*)\n\n" sp.text

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
