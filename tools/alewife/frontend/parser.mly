%{
(*
 * Copyright (c) 2017
 *	The President and Fellows of Harvard College.
 *
 * Written by David A. Holland.
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
 *)

open Pos
module T = Parsetree

%}

%token EOF
%token <int Pos.posval> NUMBER
%token <string Pos.posval> QSTRING IDENT
/* reserved words */
/* caution: EQ is a reserved word ("eq") not a = */
%token <Pos.pos> ABSTRACT ADDRESS CAN_RETYPE_MULTIPLE /*CAP*/ DEFINE EQ
%token <Pos.pos> FROM FROM_SELF GET_ADDRESS INHERIT IS_ALWAYS_COPY
%token <Pos.pos> IS_NEVER_COPY MEM_TO_PHYS SIZE SIZE_BITS
/* grouping punctuation */
%token <Pos.pos> LPAREN RPAREN LBRACE RBRACE
/* multicharacter punctuation */
/* single-character punctuation */
%token <Pos.pos> PLUS SEMIC

%type <Parsetree.def list * Parsetree.cap list> file
%start file

%%

file:
   defs caps EOF			{ (List.rev $1, List.rev $2) }
;

defs: /* built in reverse order */
     /* nil */				{ [] }
   | defs def				{ $2 :: $1 }
;

def:
   DEFINE IDENT NUMBER SEMIC		{ T.DEFINE ($2.pos, $2.x, $3.x) }
;

caps: /* built in reverse order */
     /* nil */				{ [] }
   | caps cap				{ $2 :: $1 }
;

cap:
/* CAP IDENT copy from fromself abstract inherit_ body SEMIC */
/*
 * Because the original syntax is a Parsec trashfire the hamlet
 * file actually in Barrelfish uses "cap" as both a reserved word
 * and a field name. Work around this.
 */
   IDENT IDENT copy from fromself abstract inherit_ body SEMIC {
        if $1.x <> "cap" then begin
           Pos.failat $1.pos "Parse error"
        end;
	let (multiretype, members) = $8 in {
	   T.name=$2.x;
	   T.definedat=$2.pos;
	   T.generalequality=$3;
	   T.from=$4;
	   T.fromself=$5;
	   T.multiretype;
	   T.abstract=$6;
	   T.inherit_=$7;
	   T.members;
	}
   }
;

copy:
     /* nil */				{ None }
   | IS_ALWAYS_COPY			{ Some true }
   | IS_NEVER_COPY			{ Some false }
;

from:
     /* nil */				{ None }
   | FROM IDENT				{ Some $2.x }
;

fromself:
     /* nil */				{ false }
   | FROM_SELF				{ true }
;

abstract:
     /* nil */				{ false }
   | ABSTRACT				{ true }
;

inherit_:
     /* nil */				{ None }
   | INHERIT IDENT			{ Some $2.x }
;

body:
     /* nil */				{ (false, []) }
   | LBRACE multiple fields RBRACE	{ ($2, List.rev $3) }
;

multiple:
     /* nil */				{ false }
   | CAN_RETYPE_MULTIPLE SEMIC		{ true }
;

fields: /* built in reverse order */
     /* nil */				{ [] }
   | fields field			{ $2 :: $1 }
;

field:
     ADDRESS basefield			{ T.ADDR $2 }
   | ADDRESS LBRACE addressexpr RBRACE SEMIC { T.ADDREXPR $3 }
   | SIZE basefield			{ T.SIZE ($2, false) }
   | SIZE_BITS basefield		{ T.SIZE ($2, true) }
   | SIZE LBRACE expr RBRACE SEMIC	{ T.SIZEEXPR ($3, false) }
   | SIZE_BITS LBRACE expr RBRACE SEMIC	{ T.SIZEEXPR ($3, true) }
   | EQ basefield			{ T.EQ $2 }
   | basefield				{ T.REG $1 }
;

basefield:
     QSTRING IDENT SEMIC		{ T.FIELD ($2.pos, $1.x, $2.x) }
   | IDENT IDENT SEMIC			{ T.FIELD ($2.pos, $1.x, $2.x) }
;

addressexpr:
     MEM_TO_PHYS LPAREN expr RPAREN	{ T.MEMTOPHYS $3 }
   | GET_ADDRESS LPAREN expr RPAREN	{ T.GETADDRESS $3 }
   | expr				{ T.PLAINADDR $1 }
;

expr:
     IDENT				{ T.NAME ($1.pos, $1.x) }
   | IDENT PLUS IDENT			{
	T.ADD ($2, (T.NAME ($1.pos, $1.x)), (T.NAME ($3.pos, $3.x)))
     }
;

%%
