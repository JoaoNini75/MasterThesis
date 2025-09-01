let test () =
  assert (((42 + 2) == 44));
  assert (((42 + 1) <> 44));
  assert (((42 + 1) != 44));
  assert (((42 + 2) = 44))
(*@	ensures true *)

