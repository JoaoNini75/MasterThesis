let counting (limit_l : int) (limit_r : int) =
  let acc_l = ref (0) in
  let acc_r = ref (0) in
  let i = 0 in

  while (i_l < limit_l) do
    (*@ invariant ((i_l < limit_l)) <-> ((i_r < limit_r))*)
    acc_l := (!acc_l + 1);
    acc_r := (!acc_r + 2)
  done;

  acc_l := (!acc_l * 2);
  acc_r := (!acc_r * 1);
  (!acc_l, !acc_r)
(*@ ensures true *)

