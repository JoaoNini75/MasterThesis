(*@ function bool_diff (a: bool) (b: bool) : bool =
    not (a = b) *)

let pp (c_l : bool) (c_r : bool) : int * int =
    assert ( c_l = c_r );
    if c_l then (1, 1)
    else (0, 0)
(*@ requires c_l = c_r
    ensures match result with (l_res, r_res) -> l_res = r_res *)
  