let p1 (a) =
  let x = (1 - 1) in
  let len0 = (Array.length (a) - 1) in
  let len = ref (len0) in
  Printf.printf ("%d") (len0);
  Printf.printf ("%d") (!len)
(*@ ensures true *)

let linear_search (a) =
  let len0 = p1 (a) in
  let len = ref ((p1 (a) - 1)) in
  p1 (a);
  p1 (a)
(*@ ensures true *)

