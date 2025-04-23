let bip (⌊x1 : int⌋) (⌊y1 : int⌋) : ⌊int⌋ =
    let x2 = y1 * 2 in | let y2 = y1 * 2 + 1 in
    let y2 = x2 + 1 in | let x2 = y2 - 1 in
    ⌊x2 + y2⌋
(*@ requires x1 <-> x1 && y1 <-> y1 *)