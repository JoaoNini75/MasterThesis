open Sys
open Array
open List

let header_text = {|;; test/dune

;; For each test, we declare a rule that:
;;  1. Depends on the .bip input and the .expected output
;;  2. Runs biplang.exe on the .bip, capturing stdout to .actual
;;  3. Diffs .expected vs .actual under the @runtest alias

;; If they differ, the rule fails;
;; if they're the same, the rule succeeds quietly.

|}

let rule_base_text : (string -> string -> string -> string -> string     
  -> string -> string, unit, string) format = 
{|
(rule
 (alias runtest)
 (deps
  %s.bip
  %s.expected)
 (action
		(progn
	 	(with-stdout-to %s.actual
				(run ../biplang.exe %s.bip))
	 	(run diff %s.expected %s.actual))))
|}

let write_string_to_file ~filename (s : string) =
  let oc = open_out filename in
  output_string oc s;
  close_out oc

let () =
	let exclude_files = 
		[	"dune";
		 	"informal_tests.bip";
			"update_test_dune.ml"] in

  let dir_files = readdir "../test" in

  for i = 0 to Array.length dir_files - 1 do
		let filename = get dir_files i in

		if (List.mem filename exclude_files) ||
			 (String.ends_with ~suffix:".expected" filename) then
			set dir_files i ""
		else 
			set dir_files i 
				(String.sub filename 0 (String.length filename - 4))
  done;

	let final_text = ref header_text in
	Array.sort String.compare dir_files;

	for i = 0 to Array.length dir_files - 1 do
		let filename = get dir_files i in
		if String.equal filename "" then ()
		else 
			let rule_text = Printf.sprintf rule_base_text 
				filename filename filename filename filename filename in
			final_text := !final_text ^ rule_text
	done;

	Printf.printf "test/dune updated.\n";
	write_string_to_file ~filename:"dune" !final_text
