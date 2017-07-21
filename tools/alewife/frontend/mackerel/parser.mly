%{
mackerel2 - re-implementation of tools/mackerel

the documentation is from TN-002-Mackerel.pdf

notes for research:

- "Mackerel files cannot currently say how registers in a particular space are
accessed; this functionality must be provided externally by the programmer
(typically by short inline functions)."

%}


(* Tokens *)

(* Utility ----------------------- *)

%token <int> INT
%token <int> INT_LITERAL
%token <string> IDENT
%token <string> STRING
%token BINARY
%token UNDERSCORE

%token TIMES DIV PLUS MINUS
%token PERIOD
%token EQUALS
%token COMMA
%token SEMIC
%token EOF

{%
a string literal in double quotes, which describes the device type being
specified, for example "AC97 Baseline Audio".
%}
%token DESCRIPTION

{%
An import declaration makes the definitions in a different device file
available in the current device definition,

The Mackerel compiler will search for a file with the appropriate name and
parse this at the same  time  as  the  main  file,  along  with  this  file’s
imports,  and  so  on.   Cyclic  dependencies between device files will not
cause errors, but the header files won't compile.
%}
%token IMPORT


%token <Pos.pos> LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET

(* Device ----------------------- *)

{%
A device declaration in Mackerel specifies a particular type of hardware device
(such as an ioAPIC or a particular Ethernet controller).
%}
%token DEVICE

%{
Identifier for the device type, and will be used to generate identifiers
in the target language (typically C). The name of the name of the device must
correspond to the file- name of the file, including case sensitivity:
%}
%token DEVICE_NAME

{%
Optionally specifies the bit order of the declarations inside the device file;
if specified, it must be lsbfirst (the default) or msbfirst .
%} 
%token BIT_ORDER

{%
the arguments that specify how to access the device.  They are treated as base
adresses in one of several address spaces supported by Mackerel .

Arguments are declared in C-style type notation as either of type address (in
memory space) or io (in I/O space). By convention a single device argument is
named base .
%}
%token ARGS
%token <string> ARG_IO ARG_TYPE ARG_ADDR

(* Address space ----------------------- *)

{%
Mackerel allows the specification of per-device address spaces.  This feature
can express  a  variety  of  hardware  features,  for  example  processor
model-specific  registers,  co- processor registers,  device registers that
must be accessed indirectly through another index registers, etc.
%}
%token SPACE

{% 
An identifier for the address space, and is used in register declarations
instead of a builtin space such as addr or io.
%}
%token SPACE_NAME
%token SPACE_SCHEME

{% An identifier for the argument giving the address for the registers. %}
%token SPACE_INDEX

{%
There are currently 3 built-in address spaces that Mackerel understands, and
addresses in these spaces require both a base and an offset.  
%}
%token SPACE_ADDR SPACE_IO SPACE_PCI
%token SPACE_ARG_BASE SPACE_ARG_OFFSET


(* Register ----------------------- *)

{%
A register declaration defines a particular hardware register on the device
%}
%token REGISTER

{%
An identifier for the register. Its scope is the enclosing device
declaration.
%}
%token REG_NAME

(* An (optional) attribute.  *)
%token REG_ATTR

{%
Gives the address space of this register (e.g. addr ,io ,pci ,or a
per-device user-defined address space).

As an alternative to the address space definition, and is used for registers
which have no address (or, alternatively, an implicit address). A good example
of this kind of register is a coprocessor register which requires custom
assembler instructions to read and write
%}
%token REG_SPACE_NAME

%token REGARRY REGISTER REGTYPE CONSTANTS


(* Productions *)

%type <Parsetree.def list * Parsetree.cap list> file
%start file

file:
    defs device EOF			{ (List.rev $1, List.rev $2) }
;

defs: /* built in reverse order */
    /* nil */				{ [] }
    | defs def				{ $2 :: $1 }
;

device:
(* device name [lsbfirst|msbfirst] ( args ) "description" *)
    DEVICE NAME BIT_ORDER LPAREN obj = arg_fields RPARENT DESCRIPTION {

    } SEMIC
;

arg_fields: obj = rev_arg_fields { List.rev obj };

rev_arg_felds:
    | ARG_IO
    | ARG_TYPE ARG_ADDR
;

device_fields: obj = rev_object_fields { List.rev obj };

rev_device_fields:
    | (* empty *) { [] }
;

register:
{%
register name [ attr ] [also] { noaddr | space ( address) } [" description "]
type ;
%)
    | REGISTER REG_NAME REG_ATTR REG_ALSO REG_SPACE_NAME DESCRIPTION
;
