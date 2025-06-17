let bip_short (b_l : int) (b_r : int) : int * int =
  let x_l = ref (0) in
  let x_r = ref (1) in
  (!x_l, !x_r)

let bip (b_l : int) (b_r : int) : int * int =
  let i = ref (0) in
  let j_l = ref (0) in
  let j_r = ref (b_r) in
  let x_l = ref (0) in
  let x_r = ref (0) in
  (!x_l, !x_r)

let bip_if (x1_l : int) (x1_r : int) (y1_l : bool) (y1_r : bool) : int * int =
  let x2_l = x1_l * 2 in
  let x2_r = x1_r * 2 in
  let y2_l = 34 in
  let y2_r = 34 in
  assert ( (y2_l > x2_l) = (y2_r > x2_r) );
  if y2_l > x2_l
  then 
    (x2_l + y2_l, x2_r + y2_r)
  else 
    (x2_l - y2_l, x2_r - y2_r)

let semicolon_assign () =
  let a = ref (0) in
  a := 5;
  a := !a + 1;
  !a

let bip_cycle (b_l : int) (b_r : int) (c_l : int) (c_r : int) (n_l : int) (n_r : int) : int * int =
  let i_l = ref (0) in
  let i_r = ref (0) in
  let j_l = ref (0) in
  let j_r = ref (c_r) in
  let x_l = ref (0) in
  let x_r = ref (0) in

  while !i_l < n_l do
    (*@ invariant !i_l < n_l = !i_r < n_r
        invariant !i_l >= 0 && !i_r >= 0 && !i_l = !i_r && (n_l >= 0 -> !i_l <= n_l)TODO!!! *)
    j_l := !i_l * b_l + c_l;
    x_r := !x_r + !j_r;
    x_l := !x_l + !j_l;
    j_r := !j_r + b_r;
    i_l := !i_l + 1;
    i_r := !i_r + 1
  done;

  (!x_l, !x_r)
(*@ requires true 
    ensures true )

