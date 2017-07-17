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

open Parsetree

(**************************************************************)
(* dump *)

let show'bool b =
   if b then "true" else "false"

let show'isbits isbits =
   if isbits then " (bits)" else ""

let show'geq geq = match geq with
     None -> "none"
   | Some true -> "is_always_copy"
   | Some false -> "is_never_copy"

let show'from from = match from with
     None -> "not from"
   | Some cname -> "from " ^ cname

let show'inherit inh = match inh with
     None -> "no inherit"
   | Some cname -> "inherit " ^ cname

let rec show'expr e = match e with
     NAME (_pos, name) -> name
   | ADD (_pos, e1, e2) -> show'expr e1 ^ " + " ^ show'expr e2

let show'addrexpr ae = match ae with
     MEMTOPHYS e -> "mem_to_phys(" ^ show'expr e ^ ")"
   | GETADDRESS e -> "get_address(" ^ show'expr e ^ ")"
   | PLAINADDR e -> show'expr e

let show'field (FIELD (_pos, ty, name)) =
   name ^ " : " ^ ty

let d str =
   print_string str; print_newline ()

let dump'def (DEFINE (pos, name, value)) =
   d ("at " ^ Pos.string_of_pos pos);
   d ("   " ^ name ^ " = " ^ string_of_int value)

let dump'member m = match m with
     ADDR f ->
        d ("         address: " ^ show'field f)
   | ADDREXPR ae ->
        d ("         address { " ^ show'addrexpr ae ^ " }")
   | SIZE (f, isbits) ->
        d ("         size" ^ show'isbits isbits ^ ": " ^ show'field f)
   | SIZEEXPR (e, isbits) ->
        d ("         size" ^ show'isbits isbits ^
					" { " ^ show'expr e ^ " }")
   | EQ f ->
        d ("         eq: " ^ show'field f)
   | REG f ->
        d ("         reg: " ^ show'field f)

let dump'cap {
	   name; definedat;
	   generalequality; from; fromself;
	   multiretype;
	   abstract;
	   inherit_;
	   members;
	} =
   d ("at " ^ Pos.string_of_pos definedat);
   d ("   cap " ^ name);
   d ("      generalequality " ^ show'geq generalequality);
   d ("      " ^ show'from from);
   d ("      fromself " ^ show'bool fromself);
   d ("      multiretype " ^ show'bool multiretype);
   d ("      abstract " ^ show'bool abstract);
   d ("      inherit " ^ show'inherit inherit_);
   d ("      members:");
   List.iter dump'member members

let dump (defs, caps) =
   List.iter dump'def defs;
   List.iter dump'cap caps

(**************************************************************)
(* main *)

let load file =
   let pt = Lexer.read file in
   dump pt

let main argv = match argv with
     [_argv0; hamfile] -> load hamfile
   | _ -> Util.say "Usage: hamparser file.hl"; Util.die ()

let _ = main (Array.to_list Sys.argv)
