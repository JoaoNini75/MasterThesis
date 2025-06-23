let assignment_only (x1_l : int) (x1_r : int) (y1_l : int) (y1_r : int) : int * int =
  let x2_l = y1_l * 2 in
  let y2_r = y1_r * 2 + 1 in
  let y2_l = x2_l + 1 in
  let x2_r = y2_r - 1 in
  (x2_l + y2_l, x2_r + y2_r)
(*@ requires x1_l = x1_r && y1_l = y1_r 
    ensures match result with (l_res, r_res) -> l_res = r_res *)

let bilateral_conditional (c_l : bool) (c_r : bool) : int * int =
  assert ( (c_l) = (c_r) );
  if c_l
  then 
    (1, 1)
  else 
    (0, 0)
(*@ requires c_l <-> c_r 
    ensures match result with (l_res, r_res) -> l_res = r_res *)

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
    ensures match result with (l_res, r_res) -> l_res = r_res *)

let cond_align_loops (x_l : int) (x_r : int) (n_l : int) (n_r : int) : int * int =
  let y_l = ref (x_l) in
  let y_r = ref (x_r) in
  let z_l = ref (24) in
  let z_r = ref (16) in
  let w_l = ref (0) in
  let w_r = ref (0) in
SOMETHING WENT WRONG!

  (!z_l, !z_r)
(*@ requires x_l = x_r && n_l = n_r 
    ensures match result with (l_res, r_res) -> l_res = r_res *)

