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

