all: biplang.exe
	dune exec ./biplang.exe test.py

tests: biplang.exe
	bash run-tests "dune exec ./biplang.exe"

# Make biplang.exe depend on the generated parser files
biplang.exe: parser.ml parser.mli
	dune build biplang.exe

# If either the grammar or the lexer changes, remove the old menhir outputs
parser.ml parser.mli: parser.mly lexer.mll
	rm -f parser.ml parser.mli

clean:
	dune clean

.PHONY: all clean biplang.exe tests
