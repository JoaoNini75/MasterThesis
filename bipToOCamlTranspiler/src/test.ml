let match_test (x : int) : string =
  match x with
  | 0 -> "zero"
  | 1 -> "one"
  | _ -> "other"
(*@ ensures true *)

let match_test2 (x : int) : string * string =
  let res_l = 
    ( match x with
    | 0 -> "zero"
    | 1 -> "one"
    | _ -> "other" ) in
  let res_r = 
    ( match x with
    | 0 -> "zero"
    | 1 -> "one"
    | _ -> "other" ) in
  (res_l, res_r)
(*@ ensures true *)

