type number =
  | Neg of int
  | Pos
  | Zero

type simple = int * bool

let match_assert () =
  5
(*@ ensures true *)

