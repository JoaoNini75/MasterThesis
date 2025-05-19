let bip3 (x, y) = 
    let z = ref x in
    for i = 0 to y do
        z := !z * 3
    done;
    !z