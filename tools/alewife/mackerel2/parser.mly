%{
mackerel2 - re-implementation of tools/mackerel
%}

%token DEVICE
%token LSBFIRST MSBFIRST 
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





(* part 1 *)
%start <Json.value option> prog
%%
(* part 2 *)
prog:
  | EOF       { None }
  | v = value { Some v }
  ;

(* part 3 *)
value:
  | LEFT_BRACE; obj = object_fields; RIGHT_BRACE
    { `Assoc obj }
  | LEFT_BRACK; vl = array_values; RIGHT_BRACK
    { `List vl }
  | s = STRING
    { `String s }
  | i = INT
    { `Int i }
  | x = FLOAT
    { `Float x }
  | TRUE
    { `Bool true }
  | FALSE
    { `Bool false }
  | NULL
    { `Null }
  ;

(* part 4 *)
object_fields: obj = rev_object_fields { List.rev obj };

rev_object_fields:
  | (* empty *) { [] }
  | obj = rev_object_fields; COMMA; k = ID; COLON; v = value
    { (k, v) :: obj }
  ;

(* part 5 *)
array_values:
  | (* empty *) { [] }
  | vl = rev_values { List.rev vl }
  ;

rev_values:
  | v = value { [v] }
  | vl = rev_values; COMMA; v = value
    { v :: vl }
  ;
