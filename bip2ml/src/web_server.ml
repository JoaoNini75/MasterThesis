let example (x : int) : bool =
  let y = (x + 3) in
  ((y * 2) + 4)
(*@ requires x > 0
    ensures  true *)

