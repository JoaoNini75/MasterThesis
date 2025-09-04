let assert_v2 () : unit =
  let x_l = -1 in
  let x_r = 2 in
  assert ((x_l < 5) && (x_r < 5));
  assert ((x_l < 0) && (x_r < 10))
(*@	ensures true *)
