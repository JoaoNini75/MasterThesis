let empty_args_test () =
  8 * 7
(*@ ensures true *)

let empty_args_apply_test (x) =
  empty_args_test ()
(*@ ensures true *)

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

let assert_test (x) =
  assert (1 <> 3)
(*@ ensures true *)

let funs_nested (x) =
  let fun_inner (i) =
    let i = ref (0) in

    while !i < 3 do
      i := !i + 2;
      i := !i - 1
    done;

    !i
  (*@ ensures true *)
  in
    
  fun_inner (x)
(*@ ensures true *)

