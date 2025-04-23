
all: biplang.exe
	dune exec ./biplang.exe test.py

tests: biplang.exe
	bash run-tests "dune exec ./biplang.exe"

biplang.exe:
	dune build biplang.exe

clean:
	dune clean

.PHONY: all clean biplang.exe
