type number = | Pos of int * int | Neg | Zero

let match_assert (x : int) =
  let y = 
    if x > 0 then Pos (2, 4)
    else if x < 0 then Neg
    else Zero
  in  

  let res = 
    ( match y with
    | Pos (i, n) -> 10
    | Neg -> -10
    | Zero -> 0 ) 
  in
  
  assert ((res >= -10));
  res
(*@ ensures x > 0 -> result = 10
    ensures x = 0 -> result = 0
    ensures x < 0 -> result = -10 *)

let test () = Neg

