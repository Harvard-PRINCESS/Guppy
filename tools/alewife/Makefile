.PHONY: all clean byte native test
OCB_FLAGS = -I frontend -I backend
OCB = ocamlbuild $(OCB_FLAGS)

all: native byte

clean:
	$(OCB) -clean

native:
	$(OCB) hamparser.native

byte:
	$(OCB) hamparser.byte

test: native
	./hamparser.native ../../capabilities/caps.hl
