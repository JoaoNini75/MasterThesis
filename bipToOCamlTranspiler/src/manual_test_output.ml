type signed_int =
  | Pos of int
  | Neg of int
  | Zero

let match_assert (x : int) : int =
  let y = 
    if (x > 0)
    then begin 
      Pos (x)
    end else begin 
      if (x < 0)
      then begin 
        Neg (x)
      end else begin 
        Zero
      end
    end
  in
  let res = (
    match y with
    | Pos (n) -> (n * 10)
    | Neg (n) -> (n * 2)
    | Zero -> 0
  ) in
  assert (((res = (x * 2)) || (res = (x * 10))));
  res
(*@ ensures x > 0 -> result = x * 10
    ensures x = 0 -> result = 0
    ensures x < 0 -> result = x * 2 *)

