(*@ function rec gcd (a: int) (b:int) : int =
    if b = 0 then a
    else gcd b (mod a b) *)
(*@ requires a >= 0
    requires b >= 0
    variant b *)

let gcd_iter (a0: int) (b0: int) : int =
    let b = ref b0 in
    let a = ref a0 in
    while !b <> 0 do
        (*@ invariant 0 <= !b
            invariant 0 <= !a
            invariant gcd a0 b0 = gcd !a !b
            variant !b *)
        let tmp = !a in
        a := !b;
        b := tmp mod !b
    done;
    !a
(*@ result = gcd_iter a0 b0
    requires a0 >= 0
    requires b0 >= 0
    ensures result = gcd a0 b0*)
