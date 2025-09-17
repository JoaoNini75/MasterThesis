let pow_major (limit_l : int) (limit_r : int) : int * int =
  let counter_l = ref (0) in
  let counter_r = ref (0) in

  while ((!counter_l < limit_l) || (!counter_r < limit_r)) do
    (*@ invariant (!counter_l < limit_l && mod !counter_l 3 = 0) || (!counter_r < limit_r && mod !counter_r 3 = 0) || (not (!counter_l < limit_l) && not (!counter_r < limit_r)) || (!counter_l < limit_l && !counter_r < limit_r) *)
    if ((!counter_l < limit_l) && ((!counter_l mod 4) = 0))
    then begin 
      counter_l := (!counter_l + 1)
    end else begin 
      if ((!counter_r < limit_r) && ((!counter_r mod 4) = 0))
      then begin 
        counter_r := (!counter_r + 1)
      end else begin 
        counter_l := (!counter_l + 1);
        counter_r := (!counter_r + 1)
      end
    end;

    Printf.printf "counter_l = %d; counter_r = %d\n" !counter_l !counter_r
  done;

  (!counter_l, !counter_r)
(*@ *)

let () =
  let limit = ref 0 in
  while !limit < 10 do
    Printf.printf "limit = %d\n" !limit;
    let (res_l, res_r) = pow_major (!limit) (!limit) in
    Printf.printf "res = (%d, %d)\n\n" res_l res_r;
    limit := !limit + 2
  done
