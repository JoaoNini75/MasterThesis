let pp (b_l : int) (b_r : int) (c_l : int) (c_r : int)
        (n_l : int) (n_r : int) : int * int =

    let i_l = ref 0 in
    let i_r = ref 0 in
    let j_l = ref c_l in
    let j_r = ref c_r in
    let x_l = ref 0 in
    let x_r = ref 0 in          

    while (!i_l < n_l) do
        (*@ invariant !i_l >= 0 && !i_r >= 0 && !i_l = !i_r && (n_l >= 0 -> !i_l <= n_l)
            invariant !j_l = !i_l * b_l + c_l
            invariant !j_r = !i_r * b_r + c_r
            invariant !j_l = !j_r && !x_l = !x_r 
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
    ensures match result with (l_res, r_res) -> l_res = r_res *)    
