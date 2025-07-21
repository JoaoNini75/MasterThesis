let match_test (x : int) : string =
  match x with
  | 0 -> "zero"
  | 1 -> "one"
  | _ -> "other"
(*@ ensures true *)

let match_test (x_l : int) (x_r : int) : int * int =
  let a_l = 1 in
  let a_r = 1 in
  let b_l = 
    ( match x_l with
    | 0 -> 10
    | 1 -> 11
    | _ -> -1 ) in
  let b_r = 
    ( match x_r with
    | 0 -> 10
    | 1 -> 11
    | _ -> -1 ) in
  (a_l + b_l, a_r + b_r)
(*@ ensures true *)

