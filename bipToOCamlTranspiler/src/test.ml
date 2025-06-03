let p2 =
  let x_l = ref (1) in
  let x_r = ref (1) in
  let y_l = ref (2) in
  let y_r = ref (2) in
  x_l := !x_l + 1;
  y_r := !y_r + 2;
  let z = ref (22) in
  !z

let p3 = 
  let var = p2 in
  var = p2
