open Format
open Ast_ml
open Ast_bip
open Ast_core

type node = {
  type_str: string;
  name:     string;
  value:    string;
  children: node list;
}

let mk_node t n v c =
  { type_str = t; name = n; value = v; children = c }


let mk_empty =
  mk_node "" "" "" []

let mk_cons t n children =
  mk_node t n "" children

let mk_type t children =
  mk_node t "" "" children

let mk_leaf t v =
  mk_node t "" v []


let mk_ident ident = 
  mk_leaf "ident" ident.id

let mk_ident_opt ident_opt =
  match ident_opt with
  | None -> mk_empty
  | Some ident -> mk_ident ident

let mk_ident_cap ic = 
  mk_leaf "ident_cap" ic

let mk_spec spec = 
  mk_leaf "spec" spec.text

let mk_spec_opt spec_opt =
  match spec_opt with
  | None -> mk_empty
  | Some spec -> mk_spec spec

let mk_bip_type bt =
  let value =
  match bt with
    | INT -> "int"
    | BOOL -> "bool"
    | STRING -> "string"
    | NONE -> "none"
  in
  mk_leaf "bip_type" value


let escape_json s =
  let b = Buffer.create (String.length s) in
  String.iter (fun c ->
    match c with
    | '"'  -> Buffer.add_string b "\\\""
    | '\\' -> Buffer.add_string b "\\\\"
    | '\n' -> Buffer.add_string b "\\n"
    | '\r' -> Buffer.add_string b "\\r"
    | '\t' -> Buffer.add_string b "\\t"
    | c    -> Buffer.add_char b c
  ) s;
  Buffer.contents b

let is_empty_node t n v c =
  t = "" && n = "" && v = "" && c = []

let rec print_node fmt (type_str : string) (name : string) 
  (value : string) (children : node list) =

  if is_empty_node type_str name value children then ()
  else begin
    fprintf fmt "{
      \"type\": \"%s\",\n
      \"name\": \"%s\",\n
      \"value\": \"%s\",\n
      \"children\": ["
      (escape_json type_str)
      (escape_json name)
      (escape_json value);

    ( 
      match children with
      | [] -> ()
      | _ ->
          fprintf fmt "\n";
          let first_added = ref false in

          List.iteri (fun i child ->
            let t, n, v, c = child.type_str, child.name, child.value, child.children in
            
            if !first_added && not (is_empty_node t n v c) then fprintf fmt ",\n";
            if not !first_added && not (is_empty_node t n v c) then first_added := true;
            print_node fmt t n v c
          ) children;

          fprintf fmt "\n"
    );

    fprintf fmt "]\n}"
  end


let build_ast_constant constant : node =
  let type_str = "constant" in 
  let cons_name, children = (
    match constant with
    | Cnone -> "Cnone", []
    | Cint c -> "Cint", [mk_leaf "int" (Int.to_string c)]
    | Cbool c ->  "Cbool", [mk_leaf "bool" (Bool.to_string c)]
    | Cstring c -> "Cstring", [mk_leaf "string" c]
  ) in
  mk_cons type_str cons_name children

let build_ast_unop unop : node =
  let cons_name = (
    match unop with
    | Uneg -> "Uneg"
    | Unot -> "Unot"
    | Uref -> "Uref" 
    | Uderef -> "Uderef"
  ) in
  mk_cons "unop" cons_name []

let build_ast_binop binop : node =
  let cons_name = (
    match binop with
    | Badd -> "Badd"
    | Bsub -> "Bsub"
    | Bmul -> "Bmul"
    | Bdiv -> "Bdiv"
    | Bmod -> "Bmod"        
    | Beq -> "Beq" 
    | Bneq -> "Bneq" 
    | Blt -> "Blt"
    | Ble -> "Ble"
    | Bgt -> "Bgt"
    | Bge -> "Bge"
    | Band -> "Band"
    | Bor -> "Bor"
    | Beqphy -> "Beqphy"
    | Bneqphy -> "Bneqphy"
    | Bconcat -> "Bconcat"
  ) in
  mk_cons "binop" cons_name []

let build_ast_payload pl : node =
  let children = List.map (fun pl_elem -> 
    match pl_elem with
    | PLexisting bt -> mk_cons "payload_elem" "PLexisting" [mk_bip_type bt]
    | PLnew ident -> mk_cons "payload_elem" "PLnew" [mk_ident ident]
  ) pl in
  mk_type "payload" [mk_type "payload_elem_list" children]

let build_ast_constructor cons : node =
  let id, plo = cons in
  let child1 = mk_ident_cap id in
  let child2 = ( 
    match plo with 
    | None -> mk_empty
    | Some pl -> build_ast_payload pl
  ) in
  mk_type "constructor" [child1; child2]

let build_ast_special_op_opt (special_op_opt : special_op option) : node =
  match special_op_opt with
  | None -> mk_empty
  | Some so -> 
    let value = (
      match so with
      | SOfloor -> "floor"
      | SOpipe -> "pipe"
    ) in
    mk_leaf "special_op" value

let build_ast_parameter_list (param_list : parameter list) : node =
  let build_ast_parameter param =
    match param with 
    | Punit -> mk_cons "parameter" "Punit" []
    | Param (ident, any_type_opt, special_op_opt, ident_opt) ->
      let ident_node = mk_ident ident in
      let any_node = (
        match any_type_opt with
        | None -> mk_empty
        | Some at -> 
          match at with
          | ATbt bt -> mk_bip_type bt
          | ATid ident -> mk_ident ident
      ) in
      let special_node = build_ast_special_op_opt special_op_opt in
      let ident_opt_node = (
        match ident_opt with
        | None -> mk_empty
        | Some ident -> mk_ident ident
      ) in
      let children = [ident_node; any_node; special_node; ident_opt_node] in
      mk_cons "parameter" "Param" children
  in
  let children = List.map build_ast_parameter param_list in
  mk_type "parameter_list" children

let build_ast_ret_type_opt ret_type_opt = 
  match ret_type_opt with
  | None -> mk_empty
  | Some ret_type ->
    let cons_name, children = (
    match ret_type with 
      | Retbt (bt, ident_opt) -> 
        "Retbt", [mk_bip_type bt; mk_ident_opt ident_opt]

      | Retcn (ident, ident_opt) -> 
        "Retcn", [mk_ident ident; mk_ident_opt ident_opt]
    ) in
    mk_cons "ret_type" cons_name children

let build_ast_fun_ret (fun_ret_opt : fun_ret) : node =
  match fun_ret_opt with
  | None -> mk_empty
  | Some fr ->
    let ret_type_opt, special_op_opt = fr in
    let ret_type_node = build_ast_ret_type_opt ret_type_opt in
    let special_op_node = build_ast_special_op_opt special_op_opt in
    mk_type "fun_ret" [ret_type_node; special_op_node]

let build_ast_ppd_list (ppdl : prepend_elem list) : node =
  let build_ast_ppd ppd =
    let cons_name, child = (
      match ppd with 
      | PPDid ident -> "PPDid", mk_ident ident
      | PPDcst constant -> "PPDcst", build_ast_constant constant
    ) in
    mk_cons "prepend_elem" cons_name [child]
  in
  mk_type "prepend_elem_list" (List.map build_ast_ppd ppdl)

let build_ast_pe_list (pe_list : pattern_elem list) : node =
  let build_ast_ptrn_elem pe : node =
    let cons_name, children = (
      match pe with 
      | PEid ident -> "PEid", [mk_ident ident]
      | PEcst cst -> "PEcst", [build_ast_constant cst]
      | PEwc -> "PEwc", []
    ) in
    mk_cons "pattern_elem" cons_name children
  in

  mk_type "pattern_elem_list" (List.map build_ast_ptrn_elem pe_list)



let rec build_ast_ocase_list (ocases : ocase list) : node = 
  let build_ast_opattern ptrn : node =
    let type_str = "opattern" in

    let child = (
      match ptrn with 
      | Oconstructor (ident_cap, oexpr_list) -> 
        mk_cons type_str "Oconstructor" 
          [mk_ident_cap ident_cap; build_ast_oexpr_list oexpr_list]

      | Oarray_ptrn pe_list -> 
        mk_cons type_str "Oarray_ptrn" [build_ast_pe_list pe_list]

      | Olist_fl pe_list -> 
        mk_cons type_str "Olist_fl" [build_ast_pe_list pe_list]

      | Olist_ppd pe_list -> 
        mk_cons type_str "Olist_ppd" [build_ast_pe_list pe_list]
    ) in

    mk_type type_str [child]
  in

  let build_ast_ocase case : node = 
    let optrn, oexpr = case in
    let optrn_node = build_ast_opattern optrn in
    let oexpr_node = build_ast_oexpr oexpr in
    mk_type "ocase" [optrn_node; oexpr_node]
  in

  mk_type "ocase_list" (List.map build_ast_ocase ocases)

and build_ast_olist_def (old : olist_def) : node = 
  let cons_name, child = (
    match old with 
    | OLDsimple el -> "OLDsimple", build_ast_oexpr_list el
    | OLDid ident -> "OLDid", mk_ident ident
  ) in
  mk_cons "olist_def" cons_name [child]

and build_ast_olist_def_list (oldl : olist_def list) : node = 
  mk_type "list_odef_list" (List.map build_ast_olist_def oldl)

and build_ast_oexpr (oexpr : oexpr) : node =
  let type_str = "oexpr" in
  let cons_name, children = (
    match oexpr with  
    | Onone -> "Onone", []

    | Ounit -> "Ounit", []

    | Oident ident -> "Oident", [mk_ident ident]

    | Otuple el -> "Otuple", [build_ast_oexpr_list el]

    | Ocons (ic, el) -> "Ocons", [mk_ident_cap ic; build_ast_oexpr_list el]

    | Ocst c -> "Ocst", [build_ast_constant c]

    | Ounop (op, e) -> "Ounop", [build_ast_unop op; build_ast_oexpr e]

    | Obinop (op, e1, e2) -> 
      "Obinop", 
      [build_ast_binop op; build_ast_oexpr e1; build_ast_oexpr e2]

    | Olet (id_opt, ident, e1, e2) -> 
      "Olet", 
      [mk_ident_opt id_opt; mk_ident ident;
        build_ast_oexpr e1; build_ast_oexpr e2]

    | Ofun (id, is_rec, param_list, ret_type_opt, ret_pair, oexpr_list, spec, after) -> 
      "Ofun", 
      [mk_ident id; mk_leaf "bool" (Bool.to_string is_rec);
        build_ast_parameter_list param_list; build_ast_ret_type_opt ret_type_opt;
        mk_leaf "bool" (Bool.to_string ret_pair); build_ast_oexpr_list oexpr_list;
        mk_spec spec; build_ast_oexpr after]

    | Oapp (ident, oexpr_list) -> 
      "Oapp", 
      [mk_ident ident; build_ast_oexpr_list oexpr_list]

    | Omodapp (ident_cap, ident, oexpr_list) -> 
      "Omodapp", 
      [mk_ident_cap ident_cap; mk_ident ident; build_ast_oexpr_list oexpr_list]

    | Oif (oe1, oe2, el_then, el_else) -> 
      "Oif", 
      [build_ast_oexpr oe1; build_ast_oexpr oe2; build_ast_oexpr_list el_then;
        build_ast_oexpr_list el_else]

    | Ofor (ident, e_val, e_to, spec_opt, el_body) -> 
      "Ofor", 
      [mk_ident ident; build_ast_oexpr e_val; build_ast_oexpr e_to;
        mk_spec_opt spec_opt; build_ast_oexpr_list el_body]

    | Owhile (oe1, oe2, spec_opt, oexpr_list) -> 
      "Owhile", 
      [build_ast_oexpr oe1; build_ast_oexpr oe2; mk_spec_opt spec_opt;
        build_ast_oexpr_list oexpr_list]

    | Oassign (ident1, ident2, oe1, oe2) -> 
      "Oassign", [mk_ident ident1; mk_ident ident2; build_ast_oexpr oe1;
        build_ast_oexpr oe2]

    | Oassert e -> "Oassert", [build_ast_oexpr e]

    | Omatch (ident, cases) -> 
      "Omatch", [mk_ident ident; build_ast_ocase_list cases]

    | Oarray_new (el) -> "Oarray_new", [build_ast_oexpr_list el]

    | Oarray_read (ident, e) -> 
      "Oarray_read", [mk_ident ident; build_ast_oexpr e]

    | Oarray_write (ident, e1, e2) -> 
      "Oarray_write", [mk_ident ident; build_ast_oexpr e1; build_ast_oexpr e2]

    | Olist_new ld -> "Olist_new", [build_ast_olist_def ld]

    | Olist_concat (ld1, ldl) -> 
      "Olist_concat", [build_ast_olist_def ld1; build_ast_olist_def_list ldl]
      
    | Olist_prepend (ppdl, ldl) -> 
      "Olist_prepend", [build_ast_ppd_list ppdl; build_ast_olist_def_list ldl]
    
    | Oseq (e1, e2) -> "Oseq", [build_ast_oexpr e1; build_ast_oexpr e2]
    
  ) in 
  mk_cons type_str cons_name children

and build_ast_oexpr_list (oexpr_list : oexpr list) : node =
  mk_type "oexpr_list" (List.map build_ast_oexpr oexpr_list)

let build_ast_odef (odef: odef) : node =
  let (ident, is_rec, param_list, ret_type_opt, ret_pair, oexpr_list, spec) = odef in
  let ident_node = mk_ident ident in
  let is_rec_node = mk_leaf "bool" (Bool.to_string is_rec) in
  let param_list_node = build_ast_parameter_list param_list in
  let ret_type_opt_node = build_ast_ret_type_opt ret_type_opt in
  let ret_pair_node = mk_leaf "bool" (Bool.to_string ret_pair) in
  let oexpr_list_node = build_ast_oexpr_list oexpr_list in
  let spec_node = mk_spec spec in
  mk_type 
    "odef" 
    [ident_node; is_rec_node; param_list_node; ret_type_opt_node;
      ret_pair_node; oexpr_list_node; spec_node]



let rec build_ast_case_list (cases : case list) : node = 
  let build_ast_pattern ptrn : node =
    let type_str = "pattern" in

    let child = (
      match ptrn with 
      | Econstructor (ident_cap, expr_list) -> 
        mk_cons type_str "Econstructor" 
          [mk_ident_cap ident_cap; build_ast_expr_list expr_list]

      | Earray_ptrn pe_list -> 
        mk_cons type_str "Earray_ptrn" [build_ast_pe_list pe_list]

      | Elist_fl pe_list -> 
        mk_cons type_str "Elist_fl" [build_ast_pe_list pe_list]

      | Elist_ppd pe_list -> 
        mk_cons type_str "Elist_ppd" [build_ast_pe_list pe_list]
    ) in

    mk_type type_str [child]
  in

  let build_ast_case case : node = 
    let ptrn, expr = case in
    let ptrn_node = build_ast_pattern ptrn in
    let expr_node = build_ast_expr expr in
    mk_type "case" [ptrn_node; expr_node]
  in

  mk_type "case_list" (List.map build_ast_case cases)

and build_ast_list_def (ld : list_def) : node = 
  let cons_name, child = (
    match ld with 
    | ELDsimple el -> "ELDsimple", build_ast_expr_list el
    | ELDid ident -> "ELDid", mk_ident ident
  ) in
  mk_cons "list_def" cons_name [child]

and build_ast_list_def_list (ldl : list_def list) : node = 
  mk_type "list_def_list" (List.map build_ast_list_def ldl)

and build_ast_expr (expr : expr) : node =
  let type_str = "expr" in
  let cons_name, children = (
    match expr with  
    | Eunit -> "Eunit", []

    | Eident ident -> "Eident", [mk_ident ident]

    | Etuple el -> "Etuple", [build_ast_expr_list el]

    | Econs (ic, el) -> "Econs", [mk_ident_cap ic; build_ast_expr_list el]

    | Ecst c -> "Ecst", [build_ast_constant c]

    | Eunop (op, e) -> "Eunop", [build_ast_unop op; build_ast_expr e]

    | Ebinop (op, e1, e2) -> 
      "Ebinop", 
      [build_ast_binop op; build_ast_expr e1; build_ast_expr e2]

    | Elet (id_opt, ident, e1, e2) -> 
      "Elet", 
      [mk_ident_opt id_opt; mk_ident ident;
        build_ast_expr e1; build_ast_expr e2]

    | Eletpipe (id1, val1, id2, val2, body) -> 
      "Eletpipe", 
      [mk_ident id1; build_ast_expr val1; mk_ident id2;
        build_ast_expr val2; build_ast_expr body]

    | Efun (id, is_rec, param_list, fun_ret, expr_list, spec, after) -> 
      "Efun", 
      [mk_ident id; mk_leaf "bool" (Bool.to_string is_rec);
        build_ast_parameter_list param_list; build_ast_fun_ret fun_ret;
        build_ast_expr_list expr_list; mk_spec spec; build_ast_expr after]

    | Eapp (ident, expr_list) -> 
      "Eapp", 
      [mk_ident ident; build_ast_expr_list expr_list]

    | Emodapp (ident_cap, ident, expr_list) -> 
      "Emodapp", 
      [mk_ident_cap ident_cap; mk_ident ident; build_ast_expr_list expr_list]

    | Eif (e_cnd, el_then, el_else) -> 
      "Eif", 
      [build_ast_expr e_cnd; build_ast_expr_list el_then;
        build_ast_expr_list el_else]

    | Efor (ident, e_val, e_to, spec_opt, el_body) -> 
      "Efor", 
      [mk_ident ident; build_ast_expr e_val; build_ast_expr e_to;
        mk_spec_opt spec_opt; build_ast_expr_list el_body]

    | Ewhile (e_cnd, spec_opt, el_body) -> 
      "Ewhile", 
      [build_ast_expr e_cnd; mk_spec_opt spec_opt; build_ast_expr_list el_body]

    | Ewhilecnd (cnd1, cnd2, ag1, ag2, spec_opt, body) -> 
      "Ewhilecnd", 
      [build_ast_expr cnd1; build_ast_expr cnd2; build_ast_expr ag1;
        build_ast_expr ag2; mk_spec_opt spec_opt; build_ast_expr_list body]

    | Eassign (ident, e) -> "Eassign", [mk_ident ident; build_ast_expr e]

    | Eassert e -> "Eassert", [build_ast_expr e]

    | Ematch (ident, cases) -> 
      "Ematch", [mk_ident ident;  build_ast_case_list cases]

    | Earray_new (el) -> "Earray_new", [build_ast_expr_list el]

    | Earray_read (ident, e) -> 
      "Earray_read", [mk_ident ident; build_ast_expr e]

    | Earray_write (ident, e1, e2) -> 
      "Earray_write", [mk_ident ident; build_ast_expr e1; build_ast_expr e2]

    | Elist_new ld -> "Elist_new", [build_ast_list_def ld]

    | Elist_concat (ld1, ldl) -> 
      "Elist_concat", [build_ast_list_def ld1; build_ast_list_def_list ldl]
      
    | Elist_prepend (ppdl, ldl) -> 
      "Elist_prepend", [build_ast_ppd_list ppdl; build_ast_list_def_list ldl]

    | Efloor e -> "Efloor", [build_ast_expr e]
    
    | Epipe (e1, e2) -> "Epipe", [build_ast_expr e1; build_ast_expr e2]
    
  ) in 
  mk_cons type_str cons_name children

and build_ast_expr_list (expr_list : expr list) : node =
  mk_type "expr_list" (List.map build_ast_expr expr_list)

let rec build_ast_typedef typedef : node =
  let id, child2, tdo, cons_name = (
    match typedef with
    | TDsimple (id, pl, tdo) -> (id, build_ast_payload pl, tdo, "TDsimple")
    | TDcons (id, cons_list, tdo) ->
      let children = List.map build_ast_constructor cons_list in
      let child2 = mk_type "constructor_list" children in
      (id, child2, tdo, "TDcons")
  ) in

  let child1 = mk_leaf "ident" id.id in
  let children = ( 
    match tdo with 
    | None -> [child1; child2] 
    | Some td -> [child1; child2; build_ast_typedef td]
  ) in
  mk_cons "typedef" cons_name children
  
let build_ast_def (def: def) : node =
  let (ident, is_rec, param_list, fun_ret, expr_list, spec) = def in
  let ident_node = mk_ident ident in
  let bool_node = mk_leaf "bool" (Bool.to_string is_rec) in
  let param_list_node = build_ast_parameter_list param_list in
  let fun_ret_node = build_ast_fun_ret fun_ret in
  let expr_list_node = build_ast_expr_list expr_list in
  let spec_node = mk_spec spec in
  mk_type 
    "def" 
    [ident_node; bool_node; param_list_node; fun_ret_node; expr_list_node; spec_node]

let build_bip_ast fmt (file : Ast_bip.file) =
  let node_of_decl decl : node =
    let type_str = "decl" in

    match decl with 
    | Edef def -> 
      let def_node = build_ast_def def in
      mk_cons type_str "Edef" [def_node]

    | Espec spec -> 
      let child = mk_spec spec in
      mk_cons type_str "Espec" [child]

    | Etypedef typedef -> 
      let child = build_ast_typedef typedef in
      mk_cons type_str "Etypedef" [child]

    | Eopen idcap ->
      let child = mk_ident_cap idcap in
      mk_cons type_str "Eopen" [child]

    | Einclude idcap ->
      let child = mk_ident_cap idcap in
      mk_cons type_str "Einclude" [child]
  in
  let nodes = List.map node_of_decl file in
  print_node fmt "BipLang" "" "" nodes

let build_ml_ast fmt (ofile : Ast_ml.ofile) =
  let node_of_odecl odecl : node =
    let type_str = "odecl" in

    match odecl with 
    | Odef odef -> 
      let odef_node = build_ast_odef odef in
      mk_cons type_str "Odef" [odef_node]

    | Ospec spec -> 
      let child = mk_spec spec in
      mk_cons type_str "Ospec" [child]

    | Otypedef typedef -> 
      let child = build_ast_typedef typedef in
      mk_cons type_str "Otypedef" [child]

    | Oopen idcap ->
      let child = mk_ident_cap idcap in
      mk_cons type_str "Oopen" [child]

    | Oinclude idcap ->
      let child = mk_ident_cap idcap in
      mk_cons type_str "Oinclude" [child]
  in
  let nodes = List.map node_of_odecl ofile in
  print_node fmt "OCaml" "" "" nodes

let write_bip_ast_to_file (filename : string) (ast : Ast_bip.file) : unit =
  let oc = open_out filename in
  let fmt = formatter_of_out_channel oc in
  build_bip_ast fmt ast;
  pp_print_flush fmt ();
  close_out oc

let write_ml_ast_to_file (filename : string) (ast : Ast_ml.ofile) : unit =
  let oc = open_out filename in
  let fmt = formatter_of_out_channel oc in
  build_ml_ast fmt ast;
  pp_print_flush fmt ();
  close_out oc
