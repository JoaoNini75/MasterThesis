let rec last = function 
  | [] -> None
  | [ x ] -> Some x
  | _ :: t -> last t;;

last ["a" ; "b" ; "c" ; "d"];;
last [];;

let rec last_two = function
  | [] | [_] -> None
  | [ x; y ] -> Some (x,y)
  | _ :: t -> last_two t;;

let rec nth_elem l n = function
  | [] -> None
  | h :: t -> if n = 0 then Some h else nth_elem (t (n-1));;

let rec length = function
  | [] -> 0
  | [x] -> 1
  | _ :: t -> 1 + length t;;

let rev list =
  let rec aux acc = function
    | [] -> acc
    | h :: t -> aux (h :: acc) t
  in
  aux [] list;;
  