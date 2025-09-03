let loop_unswitching (x_l : int) (x_r : int) (n_l : int) (n_r : int) (a_l, a_r) (b_l, b_r) (c_l, c_r) : unit =
  let i_l = ref (0) in
  let i_r = ref (0) in
  assert (((!i_l < n_l) = (!i_r < n_r)));
  if (x_r < 7)
  then begin 
    ()
  end else begin 
    ()
  end
(*@	requires n_l = n_r && n_l >= 0
		ensures  a_l[i_l] = a_r[i_r]
		ensures  b_l[i_l] = b_r[i_r]
		ensures  c_l[i_l] = c_r[i_r] *)

