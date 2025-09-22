let cond_align_loops (x_l : int) (x_r : int) (n_l : int) (n_r : int) : int * int =
  let y_l = ref (x_l) in
  let y_r = ref (x_r) in
  let z_l = ref (24) in
  let z_r = ref (16) in
  let w_l = ref (0) in
  let w_r = ref (0) in

  let [@ghost] y_decr_l = ref (x_l * n_l) in
  let [@ghost] y_decr_r = ref (x_r * n_r) in

  while ((!y_l > 4) || (!y_r > 4)) do
    (*@ variant   !y_decr_l + !y_decr_r
        invariant !y_decr_l >= !y_l && !y_decr_r >= !y_r
        invariant !y_decr_l >= 0 && !y_decr_r >= 0
        invariant !y_l <= x_l && !y_r <= x_r
        invariant !z_l > !z_r
        invariant !z_l >= 24 && !z_r >= 16

        invariant (!y_l > 4 && (mod !w_l 2) <> 0) || (!y_r > 4 && (mod !w_r 2) <> 0) || (not (!y_l > 4) && not (!y_r > 4)) || (!y_l > 4 && !y_r > 4) *)

    if ((!y_l > 4) && ((!w_l mod 2) <> 0))
    then begin 
      if ((!w_l mod n_l) = 0) then begin 
        z_l := (!z_l * !y_l);
        y_l := (!y_l - 1);
        y_decr_l := !y_decr_l - n_l
      end else begin 
        y_decr_l := !y_decr_l - 1
      end;

      w_l := (!w_l + 1)

    end else begin 
      if ((!y_r > 4) && ((!w_r mod 2) <> 0))
      then begin 
        if ((!w_r mod n_r) = 0)
        then begin 
          z_r := (!z_r * 2);
          y_r := (!y_r - 1);
          y_decr_r := !y_decr_r - n_r
        end else begin 
          y_decr_r := !y_decr_r - 1
        end;
        w_r := (!w_r + 1)

      end else begin 
        assert ( (((!w_l mod n_l) = 0)) = (((!w_r mod n_r) = 0)) );
        if ((!w_l mod n_l) = 0)
        then begin 
          z_l := (!z_l * !y_l);
          z_r := (!z_r * 2);
          y_l := (!y_l - 1);
          y_r := (!y_r - 1);
          y_decr_l := !y_decr_l - n_l;
          y_decr_r := !y_decr_r - n_r
        end
        else begin 
          y_decr_l := !y_decr_l - 1;
          y_decr_r := !y_decr_r - 1
        end;
        
        w_l := (!w_l + 1);
        w_r := (!w_r + 1)
      end
    end
  done;

  (!z_l, !z_r)
(*@ requires x_l = x_r && n_l = n_r && n_r > 0 && x_l >= 4
    ensures  match result with (l_res, r_res) -> l_res > r_res *)

