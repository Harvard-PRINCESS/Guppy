
#
# OCaml
#
# OCaml comes two ways: there's a native compiler that supports only
# some platforms, and a byte-compiler for the rest. This affects the
# output filenames. defs.mk should set OCAMLTYPE to either "byte" or
# "native" to choose one or the other.
#

OCAML.byte=ocamlc
OCAMLOEXT.byte=cmo
OCAMLLIBEXT.byte=cma
OCAMLDEPNATIVE.byte=
OCAMLOPT.byte=  # -g to debug, -p to profile
OCAMLPIC.byte=

OCAML.native=ocamlopt
OCAMLOEXT.native=cmx
OCAMLLIBEXT.native=cmxa
OCAMLDEPNATIVE.native=-native
OCAMLOPT.native=-O2  # -g to debug, -p to profile
OCAMLPIC.native=-nodynlink -fno-PIC

OCAML=$(OCAML.$(OCAMLTYPE))
OCAMLOEXT=$(OCAMLOEXT.$(OCAMLTYPE))
OCAMLLIBEXT=$(OCAMLLIBEXT.$(OCAMLTYPE))
OCAMLDEPNATIVE=$(OCAMLDEPNATIVE.$(OCAMLTYPE))
OCAMLOPT=$(OCAMLOPT.$(OCAMLTYPE))
OCAMLPIC=$(OCAMLPIC.$(OCAMLTYPE))

OCAMLWARNS=-w +27+29+32+39+41+44+45 -warn-error +a \
		-safe-string -strict-formats
# -short-paths

# these are the same either way
OCAMLIEXT=cmi
OCAMLDEP=ocamldep
OCAMLYACC=ocamlyacc
OCAMLLEX=ocamllex

# default to native since most people's fast build machines are x86
OCAMLTYPE=native
#OCAMLTYPE=byte



