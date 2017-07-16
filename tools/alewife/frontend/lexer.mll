(*
 * Copyright (c) 2016, 2017
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

(*
 * This file is based on the bintools gentarget lexers; there is a lot of
 * cutpaste but it's not clear how to share the bits effectively.
 *)

(* prologue code *)
{
open Pos
open Parser

(* positioning and text/value extraction *)

let curfile = ref ""
let curline = ref 0
let curcol = ref 0

let nl () =
   curline := !curline + 1;
   curcol := 1

let advance lexbuf =
   let len = Lexing.lexeme_end lexbuf - Lexing.lexeme_start lexbuf in
   curcol := !curcol + len

let pos lexbuf =
   let ret = { file = !curfile; line = !curline; column = !curcol; } in
   advance lexbuf;
   ret

let posval' lexbuf f =
   let x = f (Lexing.lexeme lexbuf) in
   { pos = (pos lexbuf); x; }

let posval lexbuf =
   posval' lexbuf (fun x -> x)

let text lexbuf =
   (posval lexbuf).x

(* string accumulation buffer *)

let stringdata = ref (Buffer.create 64)
let stringstart = ref { file=""; line=0; column=0; }
let startstring lexbuf =
   Buffer.clear !stringdata;
   stringstart := pos lexbuf
let addstring s =
   Buffer.add_string !stringdata s
let addchar c =
   addstring (String.make 1 c)
let getstring () =
   let s = Buffer.contents !stringdata in
   let p0 = !stringstart in 
   { pos = p0; x = s; }

(* identifiers and keywords *)

let keywords = Types.stringmap_of_list [
   (* bloody ocaml, you can't partially apply data constructors *)
   ("abstract", (fun pos -> ABSTRACT pos));
   ("address", (fun pos -> ADDRESS pos));
   ("can_retype_multiple", (fun pos -> CAN_RETYPE_MULTIPLE pos));
(* ("cap", (fun pos -> CAP pos)); *)
   ("define", (fun pos -> DEFINE pos));
   ("eq", (fun pos -> EQ pos));
   ("from", (fun pos -> FROM pos));
   ("from_self", (fun pos -> FROM_SELF pos));
   ("get_address", (fun pos -> GET_ADDRESS pos));
   ("inherit", (fun pos -> INHERIT pos));
   ("is_always_copy", (fun pos -> IS_ALWAYS_COPY pos));
   ("is_never_copy", (fun pos -> IS_NEVER_COPY pos));
   ("mem_to_phys", (fun pos -> MEM_TO_PHYS pos));
   ("size", (fun pos -> SIZE pos));
   ("size_bits", (fun pos -> SIZE_BITS pos));
]

let doident tval =
   try
      (Types.StringMap.find tval.x keywords) tval.pos
   with Not_found ->
      IDENT tval

(* for invalid input *)
let badchar tval =
   let postxt = Pos.string_of_pos tval.pos in
   Util.say (postxt ^ ": Invalid input character " ^ tval.x);
   Util.fail ()

let badstring pos =
   let postxt = Pos.string_of_pos pos in
   let postxt2 = Pos.string_of_pos !stringstart in
   Util.say (postxt ^ ": Unterminated string constant");
   Util.say (postxt2 ^ ": String constant began here");
   Util.fail ()

(* end of prologue code *)
}

(* common patterns *)

let ws = [' ' '\t']
let digit = ['0'-'9']
let letter = ['a'-'z' 'A'-'Z' '_']
let alnum = ['0'-'9' 'a'-'z' 'A'-'Z' '_']

(* states *)
rule base = parse
     ws+		{ advance lexbuf; base lexbuf; }
   | '\n'		{ nl (); base lexbuf }
   | '/' '*' 		{ comment lexbuf; base lexbuf }
   | digit+		{ NUMBER (posval' lexbuf int_of_string) }
   | '"' 		{ startstring lexbuf; strconst lexbuf }
   | letter alnum*	{ doident (posval lexbuf) }
   | '+'		{ PLUS (pos lexbuf) }
   | ';'		{ SEMIC (pos lexbuf) }
   | '('		{ LPAREN (pos lexbuf) }
   | ')'		{ RPAREN (pos lexbuf) }
   | '{'		{ LBRACE (pos lexbuf) }
   | '}'		{ RBRACE (pos lexbuf) }
   | _			{ badchar (posval lexbuf); base lexbuf }
   | eof		{ EOF }

and strconst = parse
     [ ^ '"' '\n' ]+	{ addstring (text lexbuf); strconst lexbuf }
   | '\\' '"'		{ addchar '"'; advance lexbuf; strconst lexbuf }
   | '"'		{ advance lexbuf; QSTRING (getstring ()) }  (* done *)
   | '\n'		{ badstring (pos lexbuf); QSTRING (getstring ())}

(* this needs to be its own state to defeat the longest-match rule *)
and comment = parse
     '*' '/'		{ }
   | '*' '*' '/'	{ }
   | '*' '\n'		{ nl (); comment lexbuf }
   | '*' _		{ comment lexbuf }
   | '/' '*'		{ (* nest *) comment lexbuf; comment lexbuf }
   | '\n'		{ nl (); comment lexbuf }
   | _			{ comment lexbuf }

(* trailer code *)
{

let dump' pos txt =
   print_string (Pos.string_of_pos pos ^ " " ^ txt);
   print_newline ()

let rec dump f b =
   match f b with
	EOF -> ()
      | NUMBER pv -> dump' pv.pos ("NUMBER " ^ string_of_int pv.x); dump f b
      | QSTRING pv -> dump' pv.pos ("QSTRING " ^ pv.x); dump f b
      | IDENT pv -> dump' pv.pos ("IDENT " ^ pv.x); dump f b
      | ABSTRACT pos -> dump' pos "ABSTRACT"; dump f b
      | ADDRESS pos -> dump' pos "ADDRESS"; dump f b
      | CAN_RETYPE_MULTIPLE pos -> dump' pos "CAN_RETYPE_MULTIPLE"; dump f b
(*    | CAP pos -> dump' pos "CAP"; dump f b *)
      | DEFINE pos -> dump' pos "DEFINE"; dump f b
      | EQ pos -> dump' pos "EQ"; dump f b
      | FROM pos -> dump' pos "FROM"; dump f b
      | FROM_SELF pos -> dump' pos "FROM_SELF"; dump f b
      | GET_ADDRESS pos -> dump' pos "GET_ADDRESS"; dump f b
      | INHERIT pos -> dump' pos "INHERIT"; dump f b
      | IS_ALWAYS_COPY pos -> dump' pos "IS_ALWAYS_COPY"; dump f b
      | IS_NEVER_COPY pos -> dump' pos "IS_NEVER_COPY"; dump f b
      | MEM_TO_PHYS pos -> dump' pos "MEM_TO_PHYS"; dump f b
      | SIZE pos -> dump' pos "SIZE"; dump f b
      | SIZE_BITS pos -> dump' pos "SIZE_BITS"; dump f b
      | LPAREN pos -> dump' pos "LPAREN"; dump f b
      | RPAREN pos -> dump' pos "RPAREN"; dump f b
      | LBRACE pos -> dump' pos "LBRACE"; dump f b
      | RBRACE pos -> dump' pos "RBRACE"; dump f b
      | PLUS pos -> dump' pos "PLUS"; dump f b
      | SEMIC pos -> dump' pos "SEMIC"; dump f b

let read pathname =
   curfile := pathname;
   curline := 1;
   curcol := 1;
   let channel = open_in pathname in
   let lexbuf = Lexing.from_channel channel in
   let lexer = base in
   let parser = Parser.file lexer in
   try
      (*dump lexer lexbuf;*)
      let decls = parser lexbuf in
      Parsecheck.check decls;
      decls
   with Parsing.Parse_error ->
      Pos.crashat (pos lexbuf) "Parse error"

}
