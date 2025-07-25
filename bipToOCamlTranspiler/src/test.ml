let app_fun (x : int) =
  x
(*@ ensures true *)

let app_mid_test (x : int) (b : bool) =
  app_fun (x);
  2 + 2
(*@ ensures true *)

let app_let_test (x : int) (b : bool) =
  let app_res = app_fun (1) in
  app_res
(*@ ensures true *)

let app_end_test (x : int) (b : bool) =
  app_fun (1)
(*@ ensures true *)

