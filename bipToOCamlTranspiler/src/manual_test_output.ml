let floors_ocaml (arg1_l : int) (arg1_r : int)
  (arg2_l : int) (arg2_r : int) : int * int =
    
  let x_l = (arg1_l * 2) in
  let x_r = (arg1_r * 2) in
  let y_l = arg2_l in
  let y_r = arg2_r in
  assert ( ((y_l > x_l)) = ((y_r > x_r)) );

  if (y_l > x_l)
  then begin 
    ((x_l + y_l), (x_r + y_r))
  end else begin 
    ((x_l - y_l), (x_r - y_r))
  end
(*@ requires arg1_l = arg1_r && arg2_l = arg2_r
    ensures  match result with (l_res, r_res) -> 
              (l_res = r_res && l_res = (
                if arg2_l > arg1_l * 2
                then arg1_l * 2 + arg2_l
                else arg1_l * 2 - arg2_l)) *)
