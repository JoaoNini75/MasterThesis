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

let match_test (x : int) (y : int) : string =
  match x with
  | 0 -> "zero"
  | y -> "y"
  | _ -> "other"
(*@ ensures true *)

let match_test2 (x_l : int) (x_r : int) : int * int =
  let a_l = 1 in
  let a_r = 1 in
  let b_l = 
    ( match x_l with
    | 0 -> 10
    | 1 -> 11
    | _ -> -1 ) in
  let b_r = 
    ( match x_r with
    | 0 -> 10
    | 1 -> 11
    | _ -> -1 ) in
  (a_l + b_l, a_r + b_r)
(*@ ensures true *)

let assignment_only (x1_l : int) (x1_r : int) (y1_l : int) (y1_r : int) : int * int =
  let x2_l = y1_l * 2 in
  let y2_r = y1_r * 2 + 1 in
  let y2_l = x2_l + 1 in
  let x2_r = y2_r - 1 in
  (x2_l + y2_l, x2_r + y2_r)
(*@ requires x1_l = x1_r && y1_l = y1_r
    ensures  match result with (l_res, r_res) -> l_res = r_res *)

let bilateral_conditional (c_l : bool) (c_r : bool) : int * int =
  assert ( (c_l) = (c_r) );
  if c_l
  then begin 
    (1, 1)
  end else begin 
    (0, 0)
  end
(*@ requires c_l <-> c_r
    ensures  match result with (l_res, r_res) -> l_res = r_res *)

let induc_var_strength_red (b_l : int) (b_r : int) (c_l : int) (c_r : int) (n_l : int) (n_r : int) : int * int =
  let i_l = ref (0) in
  let i_r = ref (0) in
  let j_l = ref (0) in
  let j_r = ref (c_r) in
  let x_l = ref (0) in
  let x_r = ref (0) in

  while !i_l < n_l do
    (*@ invariant (!i_l < n_l) <-> (!i_r < n_r)
        invariant !i_l >= 0 && !i_r >= 0 && !i_l = !i_r && (n_l >= 0 -> !i_l <= n_l)
        invariant !j_r = !i_r * b_r + c_r
        invariant !x_l = !x_r 
        variant n_l - !i_l *)
    j_l := !i_l * b_l + c_l;
    x_r := !x_r + !j_r;
    x_l := !x_l + !j_l;
    j_r := !j_r + b_r;
    i_l := !i_l + 1;
    i_r := !i_r + 1
  done;

  (!x_l, !x_r)
(*@ requires b_l = b_r && c_l = c_r && n_l = n_r
    ensures  match result with (l_res, r_res) -> l_res = r_res *)

(*@ axiom mult: forall a:int, b:int, c:int, d:int.
   0 < a -> 0 < b -> 0 < c -> 0 < d -> a > b -> c > d -> (a * c) > (b * d) *)

let cond_align_loops (x_l : int) (x_r : int) (n_l : int) (n_r : int) : int * int =
  let y_l = ref (x_l) in
  let y_r = ref (x_r) in
  let z_l = ref (24) in
  let z_r = ref (16) in
  let w_l = ref (0) in
  let w_r = ref (0) in

  while !y_l > 4 || !y_r > 4 do
    (*@ variant   !y_l + !y_r
        invariant !z_l > !z_r && !y_l = !y_r && !y_r >= 4 && !z_l > 0 && !z_r > 0 
        invariant (!y_l > 4 && mod !w_l 2 <> 0) || (!y_r > 4 && mod !w_r 2 <> 0) || (not (!y_l > 4) && not (!y_r > 4)) || (!y_l > 4 && !y_r > 4) *)
    if !y_l > 4 && !w_l mod 2 <> 0
    then begin 
      if !w_l mod n_l = 0
      then begin 
        z_l := !z_l * !y_l;
        y_l := !y_l - 1
      end else begin ()
      end;
      w_l := !w_l + 1
    end else begin 
      if !y_r > 4 && !w_r mod 2 <> 0
      then begin 
        if !w_r mod n_r = 0
        then begin 
          z_r := !z_r * 2;
          y_r := !y_r - 1
        end else begin ()
        end;
        w_r := !w_r + 1
      end else begin 
        assert ( (!w_l mod n_l = 0) = (!w_r mod n_r = 0) );
        if !w_l mod n_l = 0
        then begin 
          z_l := !z_l * !y_l;
          z_r := !z_r * 2;
          y_l := !y_l - 1;
          y_r := !y_r - 1
        end else begin ()
        end;
        w_l := !w_l + 1;
        w_r := !w_r + 1
      end
    end
  done;

  (!z_l, !z_r)
(*@ requires x_l = x_r && n_l = n_r && n_r > 0 && x_l >= 4
    ensures  match result with (l_res, r_res) -> l_res > r_res *)

let cond_align_loops_nested (x_l : int) (x_r : int) (n_l : int) (n_r : int) : int * int =
  let y_l = ref (x_l) in
  let y_r = ref (x_r) in
  let z_l = ref (24) in
  let z_r = ref (16) in
  let w_l = ref (0) in
  let w_r = ref (0) in
  let t_l = ref (0) in
  let t_r = ref (1) in

  while !y_l > 4 || !y_r > 4 do
    (*@ variant   !y_l + !y_r
        invariant !z_l > !z_r && !y_l = !y_r && !y_r >= 4 && !z_l > 0 && !z_r > 0 
        invariant (!y_l > 4 && mod !w_l 2 <> 0) || (!y_r > 4 && mod !w_r 2 <> 0) || (not (!y_l > 4) && not (!y_r > 4)) || (!y_l > 4 && !y_r > 4) *)
    if !y_l > 4 && !w_l mod 2 <> 0
    then begin 

      while !t_l < 4 || !t_r < 4 do
        (*@ variant   !t_l + !t_r 
            invariant !t_l >= 0 && !t_r >= 1 
            invariant (!t_l < 4 && mod !t_l 2 <> 0) || (!t_r < 4 && mod !t_r 2 <> 0) || (not (!t_l < 4) && not (!t_r < 4)) || (!t_l < 4 && !t_r < 4) *)
        if !t_l < 4 && !t_l mod 2 <> 0
        then begin 
          t_l := !t_l + 1
        end else begin 
          if !t_r < 4 && !t_r mod 2 <> 0
          then begin 
            t_r := !t_r + 1
          end else begin 
            t_l := !t_l + 1;
            t_r := !t_r + 1
          end
        end
      done;

      y_l := !y_l - 1;
      w_l := !w_l + 1
    end else begin 
      if !y_r > 4 && !w_r mod 2 <> 0
      then begin 

        while !t_l < 4 || !t_r < 4 do
          (*@ variant   !t_l + !t_r 
              invariant !t_l >= 0 && !t_r >= 1 
              invariant (!t_l < 4 && mod !t_l 2 <> 0) || (!t_r < 4 && mod !t_r 2 <> 0) || (not (!t_l < 4) && not (!t_r < 4)) || (!t_l < 4 && !t_r < 4) *)
          if !t_l < 4 && !t_l mod 2 <> 0
          then begin 
            t_l := !t_l + 1
          end else begin 
            if !t_r < 4 && !t_r mod 2 <> 0
            then begin 
              t_r := !t_r + 1
            end else begin 
              t_l := !t_l + 1;
              t_r := !t_r + 1
            end
          end
        done;

        y_r := !y_r - 1;
        w_r := !w_r + 1
      end else begin 

        while !t_l < 4 || !t_r < 4 do
          (*@ variant   !t_l + !t_r 
              invariant !t_l >= 0 && !t_r >= 1 
              invariant (!t_l < 4 && mod !t_l 2 <> 0) || (!t_r < 4 && mod !t_r 2 <> 0) || (not (!t_l < 4) && not (!t_r < 4)) || (!t_l < 4 && !t_r < 4) *)
          if !t_l < 4 && !t_l mod 2 <> 0
          then begin 
            t_l := !t_l + 1
          end else begin 
            if !t_r < 4 && !t_r mod 2 <> 0
            then begin 
              t_r := !t_r + 1
            end else begin 
              t_l := !t_l + 1;
              t_r := !t_r + 1
            end
          end
        done;

        y_l := !y_l - 1;
        y_r := !y_r - 1;
        w_l := !w_l + 1;
        w_r := !w_r + 1
      end
    end
  done;

  (!z_l, !z_r)
(*@ requires x_l = x_r && n_l = n_r && n_r > 0 && x_l >= 4
    ensures  match result with (l_res, r_res) -> l_res > r_res *)

let rec bip_short (b_l : int) (b_r : int) : int * int =
  let x_l = ref (0) in
  let x_r = ref (1) in
  (!x_l, !x_r)
(*@ ensures true *)

let bip (b_l : int) (b_r : int) : int * int =
  let i = ref (0) in
  let j_l = ref (0) in
  let j_r = ref (b_r) in
  let x_l = ref (0) in
  let x_r = ref (0) in
  (!x_l, !x_r)
(*@ ensures true *)

let bip_if_long (x1_l : int) (x1_r : int) (y1_l : bool) (y1_r : bool) : int * int =
  let x2_l = x1_l * 2 in
  let x2_r = x1_r * 2 in
  let y2_l = 34 in
  let y2_r = 34 in
  assert ( (y2_l > x2_l) = (y2_r > x2_r) );
  if y2_l > x2_l
  then begin 
    (x2_l + y2_l, x2_r + y2_r)
  end else begin 
    (x2_l - y2_l, x2_r - y2_r)
  end
(*@ ensures true *)

let semicolon_assign () =
  let a = ref (0) in
  a := 5;
  a := !a + 1;
  !a
(*@ ensures true *)

let bip2 (x) (y) =
  let z_l = ref (-1) in
  let z_r = ref (-1) in
  let b = not (true && false) in
  z_l := !z_l + 1;
  z_r := !z_r + 1;
  b
(*@ ensures true *)

let bip3 (x : int) (y) =
  let z = ref (x) in

  for i = 0 to y do
    z := !z * 3
  done;

  !z
(*@ ensures true *)

let fact_iter (n) =
  if n <= 1
  then begin 
    1
  end else begin 
    let res = ref (1) in

    for i = 2 to n do
      res := !res * i
    done;

    !res
  end
(*@ ensures true *)

let bip_if2 (c_l : bool) (c_r : bool) : int * int =
  assert ( (c_l) = (c_r) );
  if c_l
  then begin 
    (1, 1)
  end else begin 
    (0, 0)
  end
(*@ ensures true *)

let semicolon_test () =
  let x = ref (0) in
  x := 1;
  x := 2;
  x
(*@ ensures true *)

let gcd_iter (a0) (b0) =
  let b = ref (b0) in
  let a = ref (a0) in

  while !b <> 0 do
    let tmp = !a in
    a := !b;
    b := tmp mod !b
  done;

  !a
(*@ ensures true *)

let p2 () =
  let x_l = ref (1) in
  let x_r = ref (1) in
  let y_l = ref (2) in
  let y_r = ref (2) in
  x_l := !x_l + 1;
  y_r := !y_r + 2;
  let z = ref (22) in
  !z
(*@ ensures true *)

let app2 (arg1 : int) (arg2 : int) : int =
  arg1 * arg2
(*@ ensures true *)

let app () =
  let a = ref (4) in
  let res = fact_iter (!a * 5) in
  app2 (1 * !a) (2 * !a)
(*@ ensures true *)

