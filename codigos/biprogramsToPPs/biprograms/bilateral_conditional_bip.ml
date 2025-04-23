let bip (⌊c : bool⌋) : ⌊int⌋ =
    if ⌊c⌋ then ⌊1⌋
    else ⌊0⌋
(*@ requires c <-> c *)
  