(*@ function rec fact (n: integer) : integer =
	if n = 0 then 1 else n * fact (n-1) *)
	(*@ requires n >= 0 
		variant n *)

let fact_iter (n: int) : int =
	if n <= 1 then 1
	else
		begin 
			let res = ref 1 in
			for i = 2 to n do
				(*@ invariant !res = fact (i-1) *)
				res := !res * i
			done;
			!res
		end
(*@ result = fact_iter n
	requires n >= 0 
	ensures result = fact n *)
