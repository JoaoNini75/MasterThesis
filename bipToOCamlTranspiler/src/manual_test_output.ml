type number3 =
  | Pos3 of int
  | Neg3 of int
  | Zero3

let loop_unswitching (x_l : int) (x_r : int) (n : int array) (l : number3 array) (k : int) (a_l : int array) (a_r : int array) (b_l) (b_r) : int =
  let i_l = ref (0) in
  let i_r = ref (0) in
  i_l := (!i_l + 30);
  i_r := (!i_r + 30);
  1
(*@	ensures true *)

