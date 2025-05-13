Differences between BipLang (in) and OCaml (out)

Key points:
- Every aliased variable, x for example, needs to be translated into
    x_l and x_r depending on the program it is used on.
- The transpiler should produce the ensures match result (...) 
    automatically since the tool will be used to proof that two programs
    produce the same output.


BipLang has but OCaml does not:
- | (represents what happens in the left and on the right programs)
- ⌊ and ⌋ (means that happens the statament is the same on both programs)
- <-> (in WhyRel: equals sign with two dots above)

Ocaml has but BipLang does not:
- identifiers in BipLang cannot end with an underscore 
    (due to a conflict in the lexer caused by the new symbol RFLOOR (_|))
