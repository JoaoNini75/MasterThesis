let invert_bip (x : int) =
  -x


let triple_bip (s_l : string) (s_r : string) =
  (((s_l ^ s_l) ^ s_l), ((s_r ^ s_r) ^ s_r))


let first_bip () =
  let number_l = 1 in
  let number_r = 1 in
  let message_l = "Hello" in
  let message_r = "Hello" in
  let app_res = invert_bip (3) in
  let triple_res = triple_bip (message_l) (message_r) in
  (message_l, message_r)


