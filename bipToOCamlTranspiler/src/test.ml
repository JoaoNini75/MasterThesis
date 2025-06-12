let bip_short (b_l : int) (b_r : int) : int * int =
  let x_l = ref (0) in
  let x_r = ref (1) in
  (!x_l, !x_r)

let bip (b_l : int) (b_r : int) : int * int =(* comment1 *)
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

let semicolon_assign =
  let a = ref (0) in
  a := 5;
  a := !a + 1;
  !a

let bip_while (b_l : int) (b_r : int) (c_l : int) (c_r : int) (n_l : int) (n_r : int) : int * int =
  let i_l = ref (0) in
  let i_r = ref (0) in
  let j_l = ref (0) in
  let j_r = ref (c_r) in
  let x_l = ref (0) in
  let x_r = ref (0) in

  while !i_l < n_l do
    (*@ invariant !i_l < n_l = !i_r < n_r *)
    j_l := !i_l * b_l + c_l;
    x_r := !x_r + !j_r;
    x_l := !x_l + !j_l;
    j_r := !j_r + b_r;
    i_l := !i_l + 1;
    i_r := !i_r + 1
  done;

  (!x_l, !x_r)

let bip2 (x) (y) =
  let z_l = ref (-1) in
  let z_r = ref (-1) in
  let b = not (true && false) in
  z_l := !z_l + 1;
  z_r := !z_r + 1;
  b

let bip3 (x : int) (y) =
  let z = ref (x) in

  for i = 0 to y do
    z := !z * 3
  done;

  !z

let fact_iter (n) =
  if n <= 1
  then 
    1
  else 
    let res = ref (1) in

    for i = 2 to n do
      res := !res * i
    done;

    !res

let bip_if (c_l, c_r) : int * int =
  assert ( (c_l) = (c_r) );
  if c_l
  then 
    (1, 1)
  else 
    (0, 0)

let semicolon_test =
  let x = ref (0) in
  x := 1;
  x := 2;
  x

let gcd_iter (a0) (b0) =
  let b = ref (b0) in
  let a = ref (a0) in

  while !b <> 0 do
    let tmp = !a in
    a := !b;
    b := tmp mod !b
  done;

  !a

let p2 =
  let x_l = ref (1) in
  let x_r = ref (1) in
  let y_l = ref (2) in
  let y_r = ref (2) in
  x_l := !x_l + 1;
  y_r := !y_r + 2;
  let z = ref (22) in
  !z

let app2 (arg1 : int) (arg2 : int) : int =
  arg1 * arg2

let app =
  let a = ref (4) in
  let res = fact_iter (!a * 5) in
  app2 (1 * !a) (2 * !a)

