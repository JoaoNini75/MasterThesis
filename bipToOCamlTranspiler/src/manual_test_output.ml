let pow_major (target_l : int) (target_r : int) (multiple_of_l) (multiple_of_r) : int * int =
  let counter_l = ref (0) in
  let counter_r = ref (0) in

  while ((!counter_l < target_l) || (!counter_r < target_r)) do
    (*@ invariant (!counter_l < target_l && mod !counter_l multiple_of_l = 0) || (!counter_r < target_r && mod !counter_r multiple_of_r = 0) || (not (!counter_l < target_l) && not (!counter_r < target_r)) || (!counter_l < target_l && !counter_r < target_r) *)
    if ((!counter_l < target_l) && ((!counter_l mod multiple_of_l) = 0))
    then begin 
      counter_l := (!counter_l + 1)
    end else begin 
      if ((!counter_r < target_r) && ((!counter_r mod multiple_of_r) = 0))
      then begin 
        counter_r := (!counter_r + 1)
      end else begin 
        counter_l := (!counter_l + 1);
        counter_r := (!counter_r + 1)
      end
    end
  done;

  (!counter_l, !counter_r)
(*@ *)

