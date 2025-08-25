let mult (n : int) (m : int) = begin
  let result = ref 0 in
  let j = ref 0 in

  for i = 0 to n-1 do
    while !j < m do
      result := !result + 1;
      j := !j + 1
    done;
    j := 0;
  done;
  
  !result
end

let () =
  let res = string_of_int (mult 0 0) in
  Printf.printf "%s\n" res
