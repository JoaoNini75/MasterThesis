let x = ref (1 * 42)

let () = 
    assert (!x = 42)
