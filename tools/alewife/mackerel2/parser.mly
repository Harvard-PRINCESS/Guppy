%{
mackerel2 - re-implementation of tools/mackerel
%}

%token IMPORT

%token DEVICE
%token BIT_ORDER
%token DEVICE_NAME
%token ARGS
%token <string> ARG_IO ARG_TYPE ARG_ADDR
%token DESCRIPTION


%token REGARRY REGISTER REGTYPE CONSTANTS
%token <string> ADDR ALSO BYTEWISTE DATATYPE IO MANY PCI STEPWISE TYPE VALUEWISE

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
