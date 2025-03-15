(*@ function rec fib (n: integer) : integer =
	if n <= 1 then n else fib (n-1) + fib (n-2) *)
	(*@ requires n >= 0 
		variant n *)

let fib_iter (n: int) : int =
	if n <= 1 then n
	else
		begin
			let prev = ref 0 in 
			let res = ref 1 in
			let temp = ref 1 in

			for i = 2 to n do
				(*@ invariant !prev = fib (i-2)
					invariant !res = fib (i-1) *)
				temp := !res;
				res := !res + !prev;
				prev := !temp;
			done;

			!res
		end
(*@ result = fib_iter n
	requires n >= 0 
	ensures result = fib n *)
