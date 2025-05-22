let semicolon_test () =
    if 2 < 4
    then (
        let x = ref 0 in
        x := !x + 1;
        x
    )
    else
        let x = ref 40 in
        x := !x + 4;
        x
