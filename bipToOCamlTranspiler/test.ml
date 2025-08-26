type number = Neg | Pos | Zero

let match_assert (x : int) =
  let y = 
    if x = 0 then Neg
    else if x = 1 then Pos
    else Zero
  in  

  let res = 
    ( match y with
    | Neg -> 10
    | Pos -> 20
    | Zero -> 0 ) 
  in
  
  assert ((res >= 0));
  res
(*@ ensures x = 0 -> result = 10
    ensures x = 1 -> result = 20
    ensures x <> 0 && x <> 1 -> result = 0 *)
