let semicolon_test () =
    if 2 < 4
    then begin
        let x = ref 0 in
        x := !x + 1;
        x
    end
    else
        let x = ref 40 in
        x := !x + 4;
        x
