let bip (⌊b : int⌋) (⌊c : int⌋) (⌊n : int⌋) : ⌊int⌋ =
    ⌊let i = ref 0 in⌋;
    let j = ref 0 in; | let j = ref c in;
    ⌊let x = ref 0 in⌋;

    while (⌊!i < n⌋) do
        (*@ invariant ⌊!i >= 0⌋ 
            invariant skip | !j = !i * b + c 
            invariant !i <-> !i 
            invariant !x ¨= !x 
            variant ⌊n - !i⌋  *)
        j := !i * b + c; | x := !x + !j;
        x := !x + !j;    | j := !j + b;
        ⌊i := !i + 1⌋
    done;
    ⌊!x⌋
(*@ requires b <-> b && c <-> c && n <-> n *)
