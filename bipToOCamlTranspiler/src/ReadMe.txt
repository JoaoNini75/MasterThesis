Differences between biprograms lang (in) and OCaml (out)

Key points:
- Every aliased variable, x for example, needs to be translated into
    x_l and x_r depending on the program it is used on.
- The transpiler should produce the ensures match result (...) 
    automatically since the tool will be used to proof that two programs
    produce the same output.


Biprograms have but OCaml does not:
- | (represents what happens in the left and on the right programs)
- ⌊ and ⌋ (means that happens the statament is the same on both programs)
- <-> (in WhyRel: equals sign with two dots above)

