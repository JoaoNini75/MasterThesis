let cond_align_loops (x_l : int) (x_r : int) (n_l : int) (n_r : int) : int * int =
  let y_l = ref (x_l) in
  let y_r = ref (x_r) in
  let z_l = ref (24) in
  let z_r = ref (16) in
  let w_l = ref (0) in
  let w_r = ref (0) in

  while !y_l > 4 || !y_r > 4 do
        (*@ invariant !z_l > !z_r && !y_l = !y_r && !y_r >= 4 && ((!y_l > 4 && !w_l mod n_l <> 0) || ((!y_r > 4 && !w_r mod n_r <> 0) || ((not (!y_l > 4) && not (!y_r > 4)) || ((!y_l > 4 && !y_r > 4)) *)
    if !y_l > 4 && !w_l mod n_l <> 0
    then begin 
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
    end else begin 
      if !y_r > 4 && !w_r mod n_r <> 0
      then begin 
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
(*@ requires x_l = x_r && n_l = n_r 
    ensures match result with (l_res, r_res) -> l_res = r_res *)

