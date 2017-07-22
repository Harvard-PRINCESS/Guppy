# temporary scaffolding (swiped from bintools)

#
# This does either a program or a library depending on whether
# you set PROG or LIB.
#
# Add -I flags to OCAMLINCS.
#
# Note that OCAMLOPT is the debug/optimize setting, not a variable
# pointing to the ocamlopt program.
#

OCAMLFLAGS?=$(OCAMLOPT) $(OCAMLWARNS) $(OCAMLINCS) $(OCAMLPIC)

OCAMLLDFLAGS?=$(OCAMLINCS)
OCAMLLIBS?=
OCAMLLIBDEPS?=

.if defined(LIB)
PRODUCT=lib$(LIB).$(OCAMLLIBEXT)
.elif defined(PROG)
PRODUCT=$(PROG)
.else
.error "Define either LIB or PROG"
.endif

all: $(PRODUCT)

.SUFFIXES: .ml .mli .mll .mly

genfiles: ;

# Don't use empty() because on older bsd make versions it doesn't
# work right with loop variables.
.for S in $(SRCS)
.if $(S:M*.mli) != ""
OBJS+=$(S:T:R).$(OCAMLIEXT)
.elif $(S:M*.ml) != "" || $(S:M*.mll) != "" || $(S:M*.mly) != ""
OBJS+=$(S:T:R).$(OCAMLOEXT)
.endif
.endfor

$(PRODUCT): $(OBJS) $(OCAMLLIBDEPS)
.if defined(LIB)
	$(OCAML) -a $(OCAMLLDFLAGS) $(OCAMLLIBS) $(OBJS:N*.$(OCAMLIEXT)) -o $@
.else
	$(OCAML) $(OCAMLLDFLAGS) $(OCAMLLIBS) $(OBJS:N*.$(OCAMLIEXT)) -o $@
.endif

.for S in $(SRCS:M*.mli)
$(S:T:R).$(OCAMLIEXT): $(S)
	$(OCAML) $(OCAMLFLAGS) -c $(S)
.endfor

.for S in $(SRCS:M*.ml)
$(S:T:R).$(OCAMLOEXT): $(S)
	$(OCAML) $(OCAMLFLAGS) -c $(S)
.endfor

.for S in $(SRCS:M*.mll)
$(S:T:R).ml: $(S)
	$(OCAMLLEX) $(S)
$(S:T:R).$(OCAMLOEXT): $(S:T:R).ml
	$(OCAML) $(OCAMLFLAGS) -c $(S:.mll=.ml)
genfiles: $(S:T:R).ml
.endfor

.for S in $(SRCS:M*.mly)
$(S:T:R).mli $(S:T:R).ml: $(S)
	$(OCAMLYACC) $(S)
$(S:T:R).$(OCAMLIEXT): $(S:T:R).mli
	$(OCAML) $(OCAMLFLAGS) -c $(S:.mly=.mli)
$(S:T:R).$(OCAMLOEXT): $(S:T:R).ml $(S:T:R).$(OCAMLIEXT)
	$(OCAML) $(OCAMLFLAGS) -c $(S:.mly=.ml)
genfiles: $(S:T:R).mli $(S:T:R).ml
.endfor

depend:
	$(MAKE) genfiles
	$(OCAMLDEP) $(OCAMLDEPNATIVE) $(OCAMLINCS) $(SRCS:N*.mll:N*.mly) \
		$(SRCS:M*.mll:.mll=.ml) \
		$(SRCS:M*.mly:.mly=.mli) $(SRCS:M*.mly:.mly=.ml) \
		> .depend
-include .depend

clean distclean:
	rm -f *.$(OCAMLIEXT) *.$(OCAMLOEXT) *.cmo *.[oa] $(PRODUCT)
.for S in $(SRCS:M*.mll)
	rm -f $(S:.mll=.ml)
.endfor
.for S in $(SRCS:M*.mly)
	rm -f $(S:.mly=.mli) $(S:.mly=.ml)
.endfor

.PHONY: all depend clean distclean
