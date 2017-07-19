.PHONY: all clean byte native profile debug sanity test
OCB_FLAGS = -I frontend -I backend
OCB = ocamlbuild $(OCB_FLAGS)

all: native byte

clean:
	$(OCB) -clean

native: sanity
	$(OCB) hamparser.native

byte: sanity
	$(OCB) hamparser.byte

test: native
	./hamparser.native ../../../capabilities/caps.hl

test: byte
	./hamparser.native ../../../capabilities/caps.hl
