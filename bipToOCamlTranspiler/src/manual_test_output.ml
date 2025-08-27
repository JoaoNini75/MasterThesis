type number =
  | Neg of int
  | Pos of int * bool
  | Zero

type simple = int * bool

let test_construction (num) : number =
  let x = Pos (num, true) in
  x
(*@ ensures true *)

