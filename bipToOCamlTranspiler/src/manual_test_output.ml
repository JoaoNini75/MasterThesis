type number =
  | Neg of int
  | Pos
  | Zero

type simple = int * bool

let match_assert () : number =
  let x = Pos in
  x
(*@ ensures true *)

