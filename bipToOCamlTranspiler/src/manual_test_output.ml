let fun2 (arg1, arg2) = begin
	let a = 2 in
	let b = ref (a * 10) in

	let c = 
		if arg1 + a == arg2
		then begin arg1 * a - !b end
		else begin arg2 end
	in

	(a mod c) * !b
end