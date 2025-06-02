let bip_if (x1_l : int) (x1_r : int) (y1_l : bool) (y1_r : bool) : int * int =
  let x2_l = x1_l * 2 in
  let x2_r = x1_r * 2 in
  let y2_l = 34 in
  let y2_r = 34 in
  assert ( (y2_l > x2_l) = (y2_r > x2_r) );
  if y2_l > x2_l
  then   (x2_l + y2_l, x2_r + y2_r)
  else   (x2_l - y2_l, x2_r - y2_r)
