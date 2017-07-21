%{
mackerel2 - re-implementation of tools/mackerel
%}

(* Tokens *)

{%
An import declaration makes the definitions in a different device file
available in the current device definition,

The Mackerel compiler will search for a file with the appropriate name and
parse this at the same  time  as  the  main  file,  along  with  this  file’s
imports,  and  so  on.   Cyclic  dependencies between device files will not
cause errors, but the header files won't compile.
%}
%token IMPORT

(* ----------------------- *)

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

{%
a string literal in double quotes, which describes the device type being
specified, for example "AC97 Baseline Audio".
%}
%token DESCRIPTION

(* ----------------------- *)

{%
Mackerel allows the specification of per-device address spaces.  This feature
can express  a  variety  of  hardware  features,  for  example  processor
model-specific  registers,  co- processor registers,  device registers that
must be accessed indirectly through another index registers, etc.
%}

%token SPACE

{% 
is an identifier for the address space, and is used in register declarations
instead of a builtin space such as addr or io.
%}
%token SPACE_NAME
%token SPACE_SCHEME

{% is an identifier for the argument giving the address for the registers %}
%token SPACE_INDEX

{%
There are currently 3 built-in address spaces that Mackerel understands, and
addresses in these spaces require both a base and an offset.  
%}
%token SPACE_ADDR SPACE_IO SPACE_PCI
%token SPACE_ARG_BASE SPACE_ARG_OFFSET


(* ----------------------- *)

%token REGARRY REGISTER REGTYPE CONSTANTS
%token <string> ADDR ALSO DATATYPE IO MANY PCI TYPE 

%token <int> INT
%token <int> INT_LITERAL
%token <string> IDENT
%token <string> STRING
%token BINARY
%token UNDERSCORE

%token LEFT_BRACE RIGHT_BRACE
%token LEFT_BRACKET RIGHT_BRACKET
%token LEFT_PAREN RIGHT_PAREN
%token TIMES DIV PLUS MINUS
%token PERIOD
%token EQUALS
%token COMMA
%token SEMICOLON
%token EOF

%start <string list> prog

%%

device:
(* device name [lsbfirst|msbfirst] ( args ) "description" *)
| DEVICE NAME BIT_ORDER LEFT_PAREN obj = arg_fields RIGHT_PAREN DESCRIPTION
;

arg_fields: obj = rev_arg_fields { List.rev obj };

rev_arg_felds:
| ARG_IO
| ARG_TYPE ARG_ADDR
;

device_fields: obj = rev_object_fields { List.rev obj };

rev_device_fields:
| (* empty *) { [] }
