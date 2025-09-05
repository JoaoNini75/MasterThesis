(* Main program *)

open Format
open Lexing
open Parser
open Ast_ml
open Ast_bip
open Ast_core

type side = Left | Right

type print_format =
  | Inline 
  | Middle
  | Final
(* 
  Example:

  let p1 (a) = begin
    let len = Array.length (a) - 1 in  --- Inline (nothing more)
    Printf.printf ("%d", len);         --- Middle (newline(s) + indentation + semicolon)
    Printf.printf ("%d", 0)            --- Final  (newline(s) + indentation)
  end
  (*@ ensures true *)
*)


let usage = "
  manual use:
    dune build biplang.exe && dune exec -- ./biplang.exe manual_test.bip 

  update test/dune when you add or delete test files:
    cd test
    ocaml update_test_dune.ml

  run tests: 
    dune test

    (if lock error):
    dune clean
    dune build biplang.exe
    rm -f _build/.lock
    dune test 
"

let indent_spaces = 2
let special_cond_align_char = '?'
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



let get_const_str (const : constant) : string = 
  match const with
  | Cint  i -> string_of_int i
  | Cbool b -> string_of_bool b
  | Cstring str -> "\"" ^ String.escaped str ^ "\""
  | Cnone -> "Cnone"

let get_unop_str (unop : unop) =
  match unop with
  | Uneg -> "-"
  | Unot -> "not ("
  | Uref -> "ref ("
  | Uderef -> "!" 

let get_binop_str (binop : binop) =
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
  | Beqphy -> "=="
  | Bneqphy -> "!=" 

let get_type_str bt =
  match bt with
  | INT -> "int"
  | BOOL -> "bool"
  | STRING -> "string"
  | NONE -> ""

let get_type_str_opt (any_type_opt : any_type option) =
  match any_type_opt with
  | None -> ""
  | Some (ATbt bt) -> get_type_str bt
  | Some (ATid id) -> id.id

let get_tpmod_opt (str_opt : ident option) = 
  match str_opt with 
  | None -> ""
  | Some s -> " " ^ s.id

let pp_spec_opt spec_opt : string =
  match spec_opt with 
  | None -> ""
  | Some spec -> spec.text 

let get_ptrn_elem_str (pe : pattern_elem) =
  match pe with
  | PEid ident -> ident.id
  | PEcst c -> (get_const_str c)
  | PEwc -> "_"
  
let get_ppd_elem_str ppd =
  match ppd with
  | PPDid ident -> ident.id
  | PPDcst c -> get_const_str c

let remove_whitespace s =
  let b = Buffer.create (String.length s) in

  String.iter (fun c ->
    if c <> ' '
    then Buffer.add_char b c
  ) s;
  
  Buffer.contents b

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
      let prefix_first = 
        if first_line_diff then " "
        else indent (depth + 5) in
      let prefix_rest  = indent (depth + 5) in
      let head = prefix_first ^ trim_leading first in
      let tail = List.map (fun line -> prefix_rest ^ trim_leading line) rest in
      String.concat "\n" (head :: tail)

let indent_middle_lines depth spec =
  let repl = "\n" ^ (indent (depth / 2)) in
  let parts = String.split_on_char '\n' spec in
  let enter_char_count = List.length parts - 1 in

  if enter_char_count < 2 then spec (* no middle lines *)
  else
    let parts_arr = Array.of_list parts in
    let buf = Buffer.create (String.length spec + (enter_char_count - 1) * String.length repl) in
    
    (* For each separator index i = 0 .. enter_char_count-1:
       - if i < enter_char_count - 1 : use repl
       - else (the last separator) : keep '\n' *)
    for i = 0 to enter_char_count - 1 do
      Buffer.add_string buf parts_arr.(i);
      if i < enter_char_count - 1 
      then Buffer.add_string buf repl
      else Buffer.add_char buf '\n'
    done;

    Buffer.add_string buf parts_arr.(enter_char_count);
    Buffer.contents buf

let indent_spec_if_cond_align depth spec =
  if not (String.contains spec special_cond_align_char) 
  then spec
  else
    let updated_spec = indent_middle_lines depth spec in
    String.concat 
      (indent (depth+3)) 
      (String.split_on_char special_cond_align_char updated_spec)


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


let rec bip_to_ml_fun (ident, is_rec, param_list, fun_ret, body, spec_op, after) =
  let (ret_type_opt, special_op_opt) = 
    match fun_ret with 
    | None -> None, None
    | Some (rto, soo) -> rto, soo
  in
  (ident, is_rec, param_list, ret_type_opt, special_op_opt <> None,
    List.map (fun e -> bip_to_ml e None None) body, spec_op, bip_to_ml after None None)

and bip_to_ml_def (def: def) : odef =
  let (ident, is_rec, param_list, fun_ret, body, spec_op) = def in
  let (ret_type_opt, special_op_opt) = 
    match fun_ret with 
    | None -> None, None
    | Some (rto, soo) -> rto, soo
  in
  (ident, is_rec, param_list, ret_type_opt, special_op_opt <> None,
    List.map (fun e -> bip_to_ml e None None) body, spec_op)

and bip_to_ml_case (case: case) : ocase = 
  let (ptrn, e) = case in
  (bip_to_ml_ptrn ptrn, bip_to_ml e None None)

and bip_to_ml_ptrn (ptrn : pattern) : opattern =
  match ptrn with
  | Econstructor (idcap, el) -> 
    Oconstructor (idcap, List.map (fun e -> bip_to_ml e None None) el)
  | Earray_ptrn array -> Oarray_ptrn array
  | Elist_fl list -> Olist_fl list
  | Elist_ppd list -> Olist_ppd list

and bip_to_ml_list_def (ld : list_def) (id_side) (gen_side) : olist_def =
  match ld with 
  | ELDsimple el -> 
    OLDsimple (List.map (fun e -> bip_to_ml e id_side gen_side) el)
  | ELDid ident -> OLDid (add_side_to_id ident id_side)

and bip_to_ml (e: Ast_bip.expr) (id_side: side option) 
                                (gen_side : side option) : Ast_ml.oexpr =

  match e with  

  | Eunit -> Ounit

  | Eident ident -> Oident (add_side_to_id ident id_side)

  | Etuple el -> Otuple (List.map (fun e -> bip_to_ml e id_side gen_side) el)

  | Econs (idcap, expr_list) -> 
    Ocons (idcap, (List.map (fun e -> bip_to_ml e id_side gen_side) expr_list))

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

  | Efun (id, is_rec, param_list, fun_ret, expr_list, spec_opt, after) ->
    let (id, is_rec, param_list, fun_type, special_op_opt, oexpr_list, spec_opt, after) =
      (bip_to_ml_fun (id, is_rec, param_list, fun_ret, expr_list, spec_opt, after)) in
    Ofun (id, is_rec, param_list, fun_type, special_op_opt, oexpr_list, spec_opt, after)

  | Eapp (ident, expr_list) -> 
    Oapp (ident, (List.map (fun e -> bip_to_ml e None gen_side) expr_list))

  | Emodapp (ident_cap, ident, expr_list) -> 
    Omodapp (ident_cap, ident, (List.map (fun e -> bip_to_ml e None gen_side) expr_list))

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
      "(" ^ el_str ^ " && " ^ er_str ^ ") " in

    let final_spec_text = 
      match spec with 
      | None -> " invariant " ^ a 
      | Some sp -> sp.text ^ "\n" ^ (String.make 1 special_cond_align_char) ^ "invariant " ^ a 
    in

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
    (* rev because of the way cases are collected in the parser *)
    let ocases = List.rev (List.map (fun case -> bip_to_ml_case case) cases) in
    Omatch (ident_final, ocases)

  | Earray_new (el) -> 
    Oarray_new (List.map (fun e -> bip_to_ml e id_side gen_side) el)

  | Earray_read (ident, e) -> 
    Oarray_read (add_side_to_id ident id_side, bip_to_ml e id_side gen_side)

  | Earray_write (ident, e1, e2) -> 
    Oarray_write (add_side_to_id ident id_side,
      bip_to_ml e1 id_side gen_side, bip_to_ml e2 id_side gen_side)

  | Elist_new ld -> Olist_new (bip_to_ml_list_def ld id_side gen_side)

  | Elist_concat (ld1, ldl) -> 
      Olist_concat (bip_to_ml_list_def ld1 id_side gen_side, 
        List.map (fun ld -> bip_to_ml_list_def ld id_side gen_side) ldl)
    
  | Elist_prepend (ppdl, ldl) -> 
    (* rev because of the way ppd elems are collected in the parser *)
    Olist_prepend (List.rev ppdl,
      List.map (fun ld -> bip_to_ml_list_def ld id_side gen_side) ldl)
     
  | Efloor e -> bip_to_ml (Epipe (e, e)) None gen_side 
  
  | Epipe (e1, e2) -> 
    Oseq (bip_to_ml e1 (Some Left) gen_side, bip_to_ml e2 (Some Right) gen_side) 


let get_prefix_suffix format depth oexpr =
  let prefix = ( 
    match oexpr with
    | Owhile (_, _, _, _) -> "\n\n" ^ indent depth
    | Ofor (_, _, _, _, _) -> "\n\n" ^ indent depth
    | Omatch (_, _) -> "" 
    | Ofun (_, _, _, _, _, _, _, _) -> "\n\n"
    | Oseq (_, _) -> ""
    | _ -> "\n" ^ indent depth
  ) in

  match format with 
  | Inline -> ("", "")
  | Middle -> (prefix, ";")
  | Final -> (prefix, "")

let rec pp_oapp_core fmt oapp depth =
  let (id, oexpr_list) = oapp in
  fprintf fmt "%s" id.id;

  if List.nth oexpr_list 0 = Ounit then (
    fprintf fmt " ()"
  ) else (
    List.iter (fun oe -> 
      fprintf fmt " (%a)" 
      (fun fmt _ -> pp_oexpr fmt oe depth Inline)
      oe) oexpr_list
  )

and pp_tuple_core fmt oel depth is_cons =
  if List.length oel = 0 then ()
  else 
    let first_elem = (List.nth oel 0) in
    let is_cons_str = if is_cons then " " else "" in

    fprintf fmt "%s(%a"
      is_cons_str
      (fun fmt _ -> pp_oexpr fmt first_elem depth Inline) first_elem;
    (* just separating first elem from the rest because of the comma *)

    List.iteri (fun idx oe -> 
      if idx <> 0
      then fprintf fmt ", %a" (fun fmt _ -> pp_oexpr fmt oe depth Inline) oe
    ) oel;

    fprintf fmt ")"

and pp_opattern fmt ptrn depth =
  match ptrn with
  | Oconstructor (idcap, oel) -> 
      fprintf fmt "%s%a" 
        idcap 
        (fun fmt _ -> pp_tuple_core fmt oel depth true) oel

  | Oarray_ptrn array -> pp_ptrn_elem_list_core fmt array depth "[| " " |]" "; "
  | Olist_fl list -> pp_ptrn_elem_list_core fmt list depth "[ " " ]" "; "
  | Olist_ppd list -> pp_ptrn_elem_list_core fmt list depth "" "" " :: "


and pp_ptrn_elem_list_core fmt aptrn_list depth prefix suffix sep =
  if List.length aptrn_list = 0 
  then fprintf fmt "%s" (remove_whitespace (prefix ^ suffix))
  else 
    let first_elem = (List.nth aptrn_list 0) in
    fprintf fmt "%s%s" prefix (get_ptrn_elem_str first_elem);

    List.iteri (fun idx pe -> 
      if idx <> 0 
      then fprintf fmt "%s%s" sep (get_ptrn_elem_str pe)
    ) aptrn_list;

    fprintf fmt "%s" suffix

and pp_new_array_or_list_core fmt oel depth is_array =
  let prefix = if is_array then "[|" else "[" in
  let suffix = if is_array then "|]" else "]" in

  if List.length oel = 0 
  then fprintf fmt "%s%s" prefix suffix
  else 
    let first_elem = (List.nth oel 0) in
    fprintf fmt "%s %a"
      prefix
      (fun fmt _ -> pp_oexpr fmt first_elem depth Inline) first_elem;

    List.iteri (fun idx oe -> 
      if idx = 0 then ()
      else fprintf fmt "; %a" (fun fmt _ -> pp_oexpr fmt oe depth Inline) oe) oel;

    fprintf fmt " %s" suffix

and pp_list_def fmt old depth = 
  match old with 
  | OLDsimple oel -> 
    fprintf fmt "%a" 
      (fun fmt _ -> pp_new_array_or_list_core fmt oel depth false) oel
  | OLDid ident -> fprintf fmt "%s" ident.id

and pp_oexpr fmt (oexpr : Ast_ml.oexpr) (depth : int) (format : print_format) = 
  let (prefix, suffix) = get_prefix_suffix format depth oexpr in
  fprintf fmt "%s" prefix;
  
  match oexpr with
  | Onone -> fprintf fmt "\nSOMETHING WENT WRONG!\n"

  | Ounit -> fprintf fmt "()"

  | Oident id -> fprintf fmt "%s" id.id

  | Otuple oel -> fprintf fmt "%a" (fun fmt _ -> pp_tuple_core fmt oel depth false) oel

  | Ocons (idcap, oel) -> 
    fprintf fmt "%s%a"  
      idcap 
      (fun fmt _ -> pp_tuple_core fmt oel depth true) oel

  | Ocst c -> fprintf fmt "%s" (get_const_str c)

  | Ounop (op, e) -> 
    let operator_str = (get_unop_str op) in
    fprintf fmt "%s" operator_str;

    pp_oexpr fmt e depth Inline;

    if operator_str = "ref (" || operator_str = "not (" 
    then fprintf fmt ")"

  | Obinop (op, e1, e2) -> 
    fprintf fmt "(%a %s %a)"
      (fun fmt _ -> pp_oexpr fmt e1 depth Inline) e1
      (get_binop_str op)
      (fun fmt _ -> pp_oexpr fmt e2 depth Inline) e2;

  | Olet (id, value, body) -> 
    let indentation = indent depth in
    
    let is_oif = (
      match value with 
      | Oif (_, _, _, _) -> true
      | _ -> false
    ) in

    let is_oif_str = if is_oif then "\n" ^ (indent (depth+1)) else "" in

    fprintf fmt "let %s = %s" id.id is_oif_str;

    ( match value with 
      | Oapp (id, oexpr_list) -> 
        pp_oapp_core fmt (id, oexpr_list) depth

      | Omodapp (ic, id, oexpr_list) -> 
        fprintf fmt "%s" (ic ^ ".");
        pp_oapp_core fmt (id, oexpr_list) depth

      | Oif (cnd_l, cnd_r, e1, e2) -> 
        pp_oexpr fmt value (depth+1) Inline

      | _ -> 
        pp_oexpr fmt value depth Inline
    );

    ( 
      if is_oif 
      then fprintf fmt "\n%sin" indentation
      else fprintf fmt " in"
    );
    
    pp_oexpr fmt body depth format

  | Ofun (id, is_rec, param_list, fun_type, special_op_opt, oexpr_list, spec_opt, after) ->
    let ofun = Ofun (id, is_rec, param_list, fun_type, special_op_opt, oexpr_list, spec_opt, after) in
    pp_fun_ml fmt ofun depth format
  
  | Oif (cnd_l, cnd_r, e1, e2) -> 
    let indentation = (indent depth) in
    let len1 = List.length e1 in
    let len2 = List.length e2 in

    if cnd_r <> Onone then
      fprintf fmt "assert ( (%a) = (%a) );\n%s"
        (fun fmt _ -> pp_oexpr fmt cnd_l depth Inline) cnd_l
        (fun fmt _ -> pp_oexpr fmt cnd_r depth Inline) cnd_r
        indentation;

    fprintf fmt "if %a\n%sthen begin "  
      (fun fmt _ -> pp_oexpr fmt cnd_l (depth+1) Inline) cnd_l
      indentation;
    
    List.iteri (fun idx oe ->
      let not_last_elem = (idx < len1 - 1) in
      let format = if not_last_elem then Middle else Final in
      pp_oexpr fmt oe (depth+1) format
    ) e1;

    fprintf fmt "\n%send else begin " indentation;

    List.iteri (fun idx oe ->
      let not_last_elem = (idx < len2 - 1) in
      let format = if not_last_elem then Middle else Final in
      pp_oexpr fmt oe (depth+1) format
    ) e2;

    fprintf fmt "\n%send%s" indentation suffix

  | Ofor (id, value, e_to, spec_opt, body) -> 
    let indentation = (indent depth) in
    let spec = pp_spec_opt spec_opt in
    let specification = 
      if spec = "" then "" 
      else 
        "\n" ^ (indent (depth+1)) ^ "(*@" ^
        swap_mod_order (indent_spec (depth-2) spec true) ^ "*)"
    in

    fprintf fmt "for %s = %a to %a do%s"
      id.id
      (fun fmt _ -> pp_oexpr fmt value depth Inline) value
      (fun fmt _ -> pp_oexpr fmt e_to depth Inline) e_to
      specification; 

    let len = List.length body in
    List.iteri (fun idx oe ->
      let not_last_elem = (idx < len - 1) in
      let format = if not_last_elem then Middle else Final in
      pp_oexpr fmt oe (depth+1) format
    ) body;

    fprintf fmt "\n%sdone%s\n" indentation suffix

  | Owhile (cnd_l, cnd_r, spec_opt, body) -> 
    let indentation = (indent depth) in
    let spec = pp_spec_opt spec_opt in

    ( match cnd_r with (* simple and conditionally aligned loops *)
      | Onone ->
        let indented_spec = indent_spec_if_cond_align (depth) spec in
        let is_cond_align_loop = not (indented_spec = spec) in
        let indented_spec = 
          if is_cond_align_loop
          then indented_spec
          else indent_spec (depth-2) spec true
        in
        
        let specification = 
          if spec = "" then "" 
          else 
            "\n" ^ (indent (depth+1)) ^ "(*@" ^ 
            swap_mod_order indented_spec ^ "*)"
        in

        fprintf fmt "while %a do%s"
        (fun fmt _ -> pp_oexpr fmt cnd_l depth Inline) cnd_l
        specification

      | _ -> (* loops with pipe or floors *)
        let indented_spec = indent_spec (depth-2) spec false in
        let specification = 
          if spec = "" then "" 
          else swap_mod_order indented_spec
        in
        
        fprintf fmt "while %a do\n%s(*@@ invariant (%a) <-> (%a)\n%s*)"
          (fun fmt _ -> pp_oexpr fmt cnd_l depth Inline) cnd_l
          (indent (depth+1))
          (fun fmt _ -> pp_oexpr fmt cnd_l depth Inline) cnd_l
          (fun fmt _ -> pp_oexpr fmt cnd_r depth Inline) cnd_r
          specification
    );

    let len = List.length body in
    List.iteri (fun idx oe ->
      let not_last_elem = (idx < len - 1) in
      let format = if not_last_elem then Middle else Final in
      pp_oexpr fmt oe (depth+1) format
    ) body;
    
    fprintf fmt "\n%sdone%s\n" indentation suffix

  | Oassign (id1, id2, e1, e2) ->
    let indentation = (indent depth) in

    ( match e2 with
      | Onone -> 
        fprintf fmt "%s := %a"
          id1.id
          (fun fmt _ -> pp_oexpr fmt e1 depth Inline) e1

      | _ -> 
        fprintf fmt "%s := %a;\n%s%s := %a"
          id1.id
          (fun fmt _ -> pp_oexpr fmt e1 depth Inline) e1
          indentation
          id2.id
          (fun fmt _ -> pp_oexpr fmt e2 depth Inline) e2
    );

    fprintf fmt "%s" suffix

  | Oapp (id, oexpr_list) ->
    let oapp = (id, oexpr_list) in
    fprintf fmt "%a%s" 
      (fun fmt _ -> pp_oapp_core fmt oapp depth) oapp
      suffix

  | Omodapp (ic, id, oexpr_list) -> 
    let oapp = (id, oexpr_list) in
    fprintf fmt "%s%a%s"
      (ic ^ ".")
      (fun fmt _ -> pp_oapp_core fmt oapp depth) oapp
      suffix

  | Oassert (oe) ->
    ( match oe with 
      | Oseq (oe1, oe2) ->
        fprintf fmt "assert (%a && %a)%s"
          (fun fmt _ -> pp_oexpr fmt oe1 depth Inline) oe1
          (fun fmt _ -> pp_oexpr fmt oe2 depth Inline) oe2
          suffix
      | _ ->
        fprintf fmt "assert (%a)%s"
          (fun fmt _ -> pp_oexpr fmt oe depth Inline) oe
          suffix 
    )

  | Omatch (id, cases) -> 
    let depth = if format <> Final then (depth + 1) else depth in
    let indentation = (indent depth) in
    let par_prefix = if format <> Final then "(" else "" in

    fprintf fmt "%s\n%smatch %s with" 
      par_prefix
      indentation 
      id.id;

    List.iter (fun case ->
      let (ptrn, oe) = case in
      let is_oif_format = (
        match oe with
        | Oif (_, _, _, _) -> Middle
        | _ -> Inline
      ) in

      fprintf fmt "\n%s| %a -> %a"
        indentation
        (fun fmt _ -> pp_opattern fmt ptrn depth) ptrn
        (fun fmt _ -> pp_oexpr fmt oe (depth + 1) is_oif_format) oe
    ) cases;
    
    if format <> Final
    then fprintf fmt "\n%s)" (indent (depth-1))

  | Oarray_new oel -> 
    fprintf fmt "%a" 
      (fun fmt _ -> pp_new_array_or_list_core fmt oel depth true) oel

  | Oarray_read (ident, oe) -> 
    fprintf fmt "%s.(%a)" 
      ident.id
      (fun fmt _ -> pp_oexpr fmt oe (depth + 1) Inline) oe

  | Oarray_write (ident, oe_idx, oe_val) -> 
    fprintf fmt "%s.(%a) <- %a%s"
      ident.id
      (fun fmt _ -> pp_oexpr fmt oe_idx (depth + 1) Inline) oe_idx
      (fun fmt _ -> pp_oexpr fmt oe_val (depth + 1) Inline) oe_val
      suffix

  | Olist_new old ->
    fprintf fmt "%a" 
      (fun fmt _ -> pp_list_def fmt old depth) old

  | Olist_concat (old1, oldl) -> 
    fprintf fmt "%a " 
      (fun fmt _ -> pp_list_def fmt old1 depth) old1;

      List.iter (fun old ->
        fprintf fmt "@@ %a"
          (fun fmt _ -> pp_list_def fmt old depth) old
      ) oldl;
    
  | Olist_prepend (ppdl, oldl) -> 
    List.iter (fun ppd ->
      fprintf fmt "%s :: "
        (get_ppd_elem_str ppd)
    ) ppdl;

    let first_elem = List.nth oldl 0 in
    fprintf fmt "%a"
      (fun fmt _ -> pp_list_def fmt first_elem depth) first_elem;
    
    List.iteri (fun idx old ->
      if idx <> 0
      then fprintf fmt " @@ %a"
        (fun fmt _ -> pp_list_def fmt old depth) old
    ) oldl

  | Oseq (e1, e2) -> 
    match e1 with 
    | Oassign (id1, id2, oe1, oe2) -> 
      (* case where there are assigns on both sides of a pipe
        and the left-hand identifiers are different *)
      pp_oexpr fmt e1 depth Middle;
      pp_oexpr fmt e2 depth format

    | _ -> 
      fprintf fmt "\n%s(%a, %a)"
        (indent depth)
        (fun fmt _ -> pp_oexpr fmt e1 depth Inline) e1
        (fun fmt _ -> pp_oexpr fmt e2 depth Inline) e2


and pp_def_ml_core fmt id is_rec param_list ret_type_opt ret_pair oexpr_list spec depth = 
  let fun_type_str = 
    match ret_type_opt with
    | None -> ""
    | Some (Retbt (bt, tpmod_opt)) -> get_type_str bt ^ (get_tpmod_opt tpmod_opt)
    | Some (Retcn (ident, tpmod_opt)) -> ident.id ^ (get_tpmod_opt tpmod_opt)
  in
  let is_rec_str = if is_rec then "rec " else "" in
  let indentation = indent depth in

  fprintf fmt "%slet %s%s" indentation is_rec_str id.id;

  if List.nth param_list 0 = Punit then (
    fprintf fmt " ()"
  ) else (
    List.iter (
      fun (param) ->
        match param with
        | Punit -> fprintf fmt "\nSOMETHING WENT WRONG!\n"
        | Param (ident, param_type, special_op_opt, tpmod_opt) -> 
          let param_type_str = get_type_str_opt param_type in
          let tpmod_str = get_tpmod_opt tpmod_opt in

          match special_op_opt with 
          | None -> (
            if param_type_str = "" 
            then fprintf fmt " (%s)" ident.id
            else 
              fprintf fmt " (%s : %s%s)" 
                ident.id 
                param_type_str 
                tpmod_str )

          | _ -> (
            let id1 = ident.id ^ "_l" in
            let id2 = ident.id ^ "_r" in
            if param_type_str = "" 
            then fprintf fmt " (%s) (%s)" id1 id2
            else 
              fprintf fmt " (%s : %s%s) (%s : %s%s)" 
                id1 
                param_type_str 
                tpmod_str 
                id2 
                param_type_str 
                tpmod_str ) 

    ) param_list;
  );

  if fun_type_str = "" then (
    fprintf fmt " ="
  ) else (
    if ret_pair
    then fprintf fmt " : %s * %s =" fun_type_str fun_type_str
    else fprintf fmt " : %s =" fun_type_str
  );

  let len = List.length oexpr_list in
  List.iteri (fun idx oe ->
    let not_last_elem = (idx < len - 1) in
    let format = if not_last_elem then Middle else Final in
    pp_oexpr fmt oe (depth+1) format
  ) oexpr_list;

  let specification = 
    if spec.text = "" then ""
    else "(*@" ^ (swap_mod_order spec.text) ^ "*)" in

  specification

and pp_def_ml fmt (odef: Ast_ml.odef) =
  let (id, is_rec, param_list, ret_type_opt, ret_pair, oexpr_list, spec) = odef in 
  let specification = (pp_def_ml_core fmt id is_rec param_list ret_type_opt ret_pair oexpr_list spec 0) in
  fprintf fmt "\n%s\n\n" specification
  
and pp_fun_ml fmt (oe: Ast_ml.oexpr) depth format = 
  match oe with
  | Ofun (id, is_rec, param_list, ret_type_opt, ret_pair, oexpr_list, spec, after) ->
    let specification = (pp_def_ml_core fmt id is_rec param_list ret_type_opt ret_pair oexpr_list spec depth) in
    fprintf fmt "\n%s%s\n%sin\n%s%a" 
      (indent depth)
      specification
      (indent depth)
      (indent (depth+1))
      (fun fmt _ -> pp_oexpr fmt after depth format) after

  | _ -> fprintf fmt "\n\n\nERROR!\n\n\n"


let pp_spec_ml fmt (sp: spec) =
  fprintf fmt "(*@%s*)\n\n" sp.text

let pp_payload fmt (pl : payload) =
  List.iteri (fun idx pl_elem -> 
    let pl_elem_str =
      match pl_elem with 
      | PLexisting bt -> 
        let tp_str = get_type_str bt in
        if idx = 0 then tp_str
        else " * " ^ tp_str

      | PLnew ident ->
        if idx = 0 then ident.id
        else " * " ^ ident.id 
    in
    fprintf fmt "%s" pl_elem_str
  ) pl

let rec pp_typedef_ml fmt (td: typedef) (is_and : bool) =
  let keyword = if is_and then "and" else "type" in
  let and_type_def_opt =
  ( match td with 
    | TDsimple (typename, payload, and_type_def_opt) ->
      fprintf fmt "%s %s = %a" keyword typename.id pp_payload payload;
      and_type_def_opt

    | TDcons (typename, cons_list, and_type_def_opt) ->
      fprintf fmt "%s %s =" keyword typename.id;

      List.iter (fun cons -> 
        let (idcap, payload_opt) = cons in

        fprintf fmt "\n%s| %s" 
          (indent 1)
          idcap;

        match payload_opt with
        | None -> ()
        | Some payload -> 
          fprintf fmt " of %a" pp_payload payload

      ) cons_list;

      and_type_def_opt
  ) in
  
  fprintf fmt "\n\n";
  match and_type_def_opt with 
  | None -> ()
  | Some atd -> pp_typedef_ml fmt atd true

let pp_open fmt idcap =
  fprintf fmt "open %s\n\n" idcap

let pp_include fmt idcap =
  fprintf fmt "include %s\n\n" idcap

let pp_file_ml fmt (file : Ast_ml.ofile) =
  (*fprintf fmt "\n\nOCaml code:\n\n";*)
  List.iter (fun odecl ->
    match odecl with 
    | Odef odef -> pp_def_ml fmt odef
    | Ospec ospec -> pp_spec_ml fmt ospec
    | Otypedef otypedef -> pp_typedef_ml fmt otypedef false
    | Oopen idcap -> pp_open fmt idcap
    | Oinclude idcap -> pp_include fmt idcap
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
    | Etypedef typedef -> (Otypedef typedef)
    | Eopen open_decl -> (Oopen open_decl)
    | Einclude include_decl -> (Oinclude include_decl)
  ) file

let pp_ml (ofile : Ast_ml.ofile) =
  printf "@[%a@]@." pp_file_ml ofile


let () =
  let c = open_in file in
  let lb = Lexing.from_channel c in
  try
    let f = Parser.file Lexer.next_token lb in
    close_in c;

    let ofile = bip_to_ml_file f in
    pp_ml ofile; (* print OCaml code to terminal *)
    write_ml_to_file "manual_test_output.ml" ofile; (* print OCaml code to file *)

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
