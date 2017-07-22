
/*
 * Copyright (c) 2017
 *	The President and Fellows of Harvard College.
 *
 * Written by Alexander H. Patel.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


/* mackerel2 - re-implementation of tools/mackerel */
/* the documentation is from TN-002-Mackerel.pdf */


/* Tokens */

/* Utility ----------------------- */

%token <int> INT
%token <int> INT_LITERAL
%token <string> IDENT
%token <string> STRING
%token <string> BINARY
%token UNDERSCORE

%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET
%token TIMES DIV PLUS MINUS EQUALS
%token PERIOD COMMA SEMIC EOF

/* a string literal in double quotes, which describes the device type being
 * specified, for example "AC97 Baseline Audio".
 */
%}
%token DESCRIPTION

/* An import declaration makes the definitions in a different device file
 * available in the current device definition,
 * 
 * The Mackerel compiler will search for a file with the appropriate name and
 * parse this at the same  time  as  the  main  file,  along  with  this  file’s
 * imports,  and  so  on.   Cyclic  dependencies between device files will not
 * cause errors, but the header files won't compile.
 */
%token IMPORT

/* Device ----------------------- */

/* A device declaration in Mackerel specifies a particular type of hardware device
 * (such as an ioAPIC or a particular Ethernet controller).
 */
%token DEVICE

/* Identifier for the device type, and will be used to generate identifiers
 * in the target language (typically C). The name of the name of the device must
 * correspond to the file- name of the file, including case sensitivity.
 */
%token DEVICE_NAME

/* Optionally specifies the bit order of the declarations inside the device file;
 * if specified, it must be lsbfirst (the default) or msbfirst .
 */
%} 
%token BIT_ORDER

/* the arguments that specify how to access the device.  They are treated as base
 * adresses in one of several address spaces supported by Mackerel .
 *
 * Arguments are declared in C-style type notation as either of type address (in
 * memory space) or io (in I/O space). By convention a single device argument is
 * named base .
 */
%}
%token ARGS
%token <string> ARG_IO ARG_TYPE ARG_ADDR

/* Address space ----------------------- */

/* Mackerel allows the specification of per-device address spaces.  This feature
 * can express  a  variety  of  hardware  features,  for  example  processor
 * model-specific  registers,  co- processor registers,  device registers that
 * must be accessed indirectly through another index registers, etc.
 */
%token SPACE

/* An identifier for the address space, and is used in register declarations
 * instead of a builtin space such as addr or io.
 */
%token SPACE_NAME
%token SPACE_SCHEME

/* An identifier for the argument giving the address for the registers. */
%token SPACE_INDEX

/* There are currently 3 built-in address spaces that Mackerel understands, and
 * addresses in these spaces require both a base and an offset.  
 */
%token SPACE_ADDR SPACE_IO SPACE_PCI
%token SPACE_ARG_BASE SPACE_ARG_OFFSET


/* Register ----------------------- */

/* A register declaration defines a particular hardware register on the device */
%token REGISTER

/* An identifier for the register. Its scope is the enclosing device
 * declaration.
 */
%token REG_NAME

/* An (optional) attribute. */
%} 
%token REG_ATTR

/* 
 * Gives the address space of this register (e.g. addr ,io ,pci ,or a
 * per-device user-defined address space).
 * 
 * As an alternative to the address space definition, and is used for registers
 * which have no address (or, alternatively, an implicit address). A good example
 * of this kind of register is a coprocessor register which requires custom
 * assembler instructions to read and write
 */ 
%token REG_SPACE_NAME

%token REGARRY REGISTER REGTYPE CONSTANTS


/* Productions */

%start <string list> main
%%


file:
    defs device EOF			{ (List.rev $1, List.rev $2) }
;

defs: /* built in reverse order */
    /* nil */				{ [] }
    | defs def				{ $2 :: $1 }
;

/* device name [lsbfirst|msbfirst] ( args ) "description" */
device:
    DEVICE NAME endian LPAREN obj = arg_fields RPARENT DESCRIPTION {

    } SEMIC
;

endian:
     /* nil */				{ None }
   | LSBFIRST 				{ Some true }
   | MSBFIRST 				{ Some false }
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

/*
 * register name [ attr ] [also] { noaddr | space ( address) }
 * [" description "] type ;
/* 
register:
    | REGISTER REG_NAME REG_ATTR REG_ALSO REG_SPACE_NAME DESCRIPTION
;
