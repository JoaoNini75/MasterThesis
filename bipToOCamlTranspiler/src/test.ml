let funs_nested (x) =
  let fun_inner (i) =
    let i = ref (0) in

    while !i < 3 do
      i := !i + 2;
      i := !i - 1
    done;

    !i
  (*@ ensures true *)
  in
    
  fun_inner (x)
(*@ ensures true *)

let match_test (x : int) : string =
  match x with
  | 0 -> "zero"
  | 1 -> "one"
  | _ -> "other"
(*@ ensures true *)

let match_test2 (x_l : int) (x_r : int) : int * int =
  let a_l = 1 in
  let a_r = 1 in
  let b_l = 
    ( match x_l with
    | 0 -> 10
    | 1 -> 11
    | _ -> -1 ) in
  let b_r = 
    ( match x_r with
    | 0 -> 10
    | 1 -> 11
    | _ -> -1 ) in
  (a_l + b_l, a_r + b_r)
(*@ ensures true *)

let app_fun (x : int) (b : bool) =
  x
(*@ ensures true *)

let assert_and_app_test (x : int) (b : bool) =
  let app_res = 
  app_fun (1) (true); in
  assert (1 = app_res)
(*@ ensures true *)

let assignment_only (x1_l : int) (x1_r : int) (y1_l : int) (y1_r : int) : int * int =
  let x2_l = y1_l * 2 in
  let y2_r = y1_r * 2 + 1 in
  let y2_l = x2_l + 1 in
  let x2_r = y2_r - 1 in
  (x2_l + y2_l, x2_r + y2_r)
(*@ requires x1_l = x1_r && y1_l = y1_r
    ensures  match result with (l_res, r_res) -> l_res = r_res *)

let bilateral_conditional (c_l : bool) (c_r : bool) : int * int =
  assert ( (c_l) = (c_r) );
  if c_l
  then begin 
    (1, 1)
  end else begin 
    (0, 0)
  end
(*@ requires c_l <-> c_r
    ensures  match result with (l_res, r_res) -> l_res = r_res *)

let induc_var_strength_red (b_l : int) (b_r : int) (c_l : int) (c_r : int) (n_l : int) (n_r : int) : int * int =
  let i_l = ref (0) in
  let i_r = ref (0) in
  let j_l = ref (0) in
  let j_r = ref (c_r) in
  let x_l = ref (0) in
  let x_r = ref (0) in

  while !i_l < n_l do
    (*@ invariant (!i_l < n_l) <-> (!i_r < n_r)
        invariant !i_l >= 0 && !i_r >= 0 && !i_l = !i_r && (n_l >= 0 -> !i_l <= n_l)
        invariant !j_r = !i_r * b_r + c_r
        invariant !x_l = !x_r 
        variant n_l - !i_l *)
    j_l := !i_l * b_l + c_l;
    x_r := !x_r + !j_r;
    x_l := !x_l + !j_l;
    j_r := !j_r + b_r;
    i_l := !i_l + 1;
    i_r := !i_r + 1
  done;

  (!x_l, !x_r)
(*@ requires b_l = b_r && c_l = c_r && n_l = n_r
    ensures  match result with (l_res, r_res) -> l_res = r_res *)

