type number =
  | Neg of int
  | Pos of int * bool
  | Zero

type simple = number * bool

and complex =
  | Num1 of simple * int
  | Num2 of simple * bool

and third = complex * simple

let test_construction (num) : number =
  let x = Pos (num, true) in
  let y = (x, true) in
  x
(*@ ensures true *)

