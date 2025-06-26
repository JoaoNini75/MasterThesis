let assignment_only (x1_l : int) (x1_r : int) (y1_l : int) (y1_r : int) : int * int =
  let x2_l = y1_l * 2 in
  let y2_r = y1_r * 2 + 1 in
  let y2_l = x2_l + 1 in
  let x2_r = y2_r - 1 in
  (x2_l + y2_l, x2_r + y2_r)
(*@ requires x1_l = x1_r && y1_l = y1_r
    ensures  match result with (l_res, r_res) -> l_res = r_res  *)

let bilateral_conditional (c_l : bool) (c_r : bool) : int * int =
  assert ( (c_l) = (c_r) );
  if c_l
  then begin 
    (1, 1)
  end else begin 
    (0, 0)
  end
(*@ requires c_l <-> c_r
    ensures  match result with (l_res, r_res) -> l_res = r_res  *)

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
    ensures  match result with (l_res, r_res) -> l_res = r_res  *)

(*@ axiom mult: forall a:int, b:int, c:int, d:int.
   0 < a -> 0 < b -> 0 < c -> 0 < d -> a > b -> c > d -> (a * c) > (b * d) *)

let cond_align_loops (x_l : int) (x_r : int) (n_l : int) (n_r : int) : int * int =
  let y_l = ref (x_l) in
  let y_r = ref (x_r) in
  let z_l = ref (24) in
  let z_r = ref (16) in
  let w_l = ref (0) in
  let w_r = ref (0) in

  while !y_l > 4 || !y_r > 4 do
        (*@ variant   !y_l + !y_r
        invariant !z_l > !z_r && !y_l = !y_r && !y_r >= 4 && !z_l > 0 && !z_r > 0 && ((!y_l > 4 && mod !w_l n_l <> 0) || (!y_r > 4 && mod !w_r n_r <> 0) || (not (!y_l > 4) && not (!y_r > 4)) || (!y_l > 4 && !y_r > 4)) *)
    if !y_l > 4 && !w_l mod n_l <> 0
    then begin 
      if !w_l mod n_l = 0
      then begin 
        z_l := !z_l * !y_l;
        y_l := !y_l - 1
      end else begin 
        ()
      end;
      w_l := !w_l + 1
    end else begin 
      if !y_r > 4 && !w_r mod n_r <> 0
      then begin 
        if !w_r mod n_r = 0
        then begin 
          z_r := !z_r * 2;
          y_r := !y_r - 1
        end else begin 
          ()
        end;
        w_r := !w_r + 1
      end else begin 
        assert ( (!w_l mod n_l = 0) = (!w_r mod n_r = 0) );
        if !w_l mod n_l = 0
        then begin 
          z_l := !z_l * !y_l;
          z_r := !z_r * 2;
          y_l := !y_l - 1;
          y_r := !y_r - 1
        end else begin 
          ()
        end;
        w_l := !w_l + 1;
        w_r := !w_r + 1
      end
    end
  done;

  (!z_l, !z_r)
(*@ requires x_l = x_r && n_l = n_r && n_r > 0 && x_l >= 4
    ensures  match result with (l_res, r_res) -> l_res > r_res  *)

