let mult_biplang (n_l : int) (n_r : int) (m_l : int) (m_r : int) : int * int =
  let i_l = ref (0) in
  let i_r = ref (0) in
  let res_l = ref (0) in
  let res_r = ref (0) in

  while (!i_l < n_l) do
    (*@ invariant ((!i_l < n_l)) <-> ((!i_r < n_r))
        variant   n_l - !i_l
        invariant !i_l = !i_r && !res_l = ! res_r *)
    let previous_res_l = !res_l in
    let j_l = ref (0) in
    let j_r = ref (0) in    

    while (!j_l < m_l) do
      (*@ variant   m_l - !j_l
          invariant 0 <= !j_l && !j_l <= m_l && !res_l = !res_r + !j_l *)
      res_l := (!res_l + 1);
      j_l := (!j_l + 1)
    done;
    
    res_r := (!res_r + m_r);
    assert ((!res_l = (previous_res_l + m_l)));
    i_l := (!i_l + 1);
    i_r := (!i_r + 1)
  done;

  (!res_l, !res_r)
(*@ requires n_l = n_r && m_l = m_r && m_l >= 0 
		ensures  match result with (l_res, r_res) -> l_res = r_res *)

