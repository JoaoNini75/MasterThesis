let pp (x1_l : int) (x1_r : int) (y1_l : int) (y1_r : int) : int * int =
    let x2_l = y1_l * 2 in
    let y2_r = y1_r * 2 + 1 in
    let y2_l = x2_l + 1 in
    let x2_r = y2_r - 1 in
        (x2_l + y2_l, x2_r + y2_r)
(* (* *)*)