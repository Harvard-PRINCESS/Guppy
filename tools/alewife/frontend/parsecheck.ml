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

(*
 * Postprocessing check for parser.
 *)

open Parsetree

type ctx = {
   constants: Pos.pos Types.StringMap.t ref;
   caps: Pos.pos Types.StringMap.t ref;
   fields: Pos.pos Types.StringMap.t ref;
}

let newctx () = {
   constants = ref Types.StringMap.empty;
   caps = ref Types.StringMap.empty;
   fields = ref Types.StringMap.empty;
}

let check'def ctx (DEFINE (pos, name, _value)) =
   try
      let oldpos = Types.StringMap.find name !(ctx.constants) in
      Pos.failat pos ("Redefinition of constant " ^ name);
      Pos.failat oldpos ("Previous definition")
   with Not_found ->
      ctx.constants := Types.StringMap.add name pos !(ctx.constants)

let rec check'expr ctx e = match e with
     NAME (pos, name) -> begin
        try
           let _ = Types.StringMap.find name !(ctx.constants) in
           () (* ok *)
        with Not_found -> try
           let _ = Types.StringMap.find name !(ctx.fields) in
           () (* ok *)
        with Not_found ->
           Pos.failat pos ("Undefined constant or field " ^ name)
     end
   | ADD (_pos, e1, e2) ->
        check'expr ctx e1;
        check'expr ctx e2

let check'addrexpr ctx ae = match ae with
     MEMTOPHYS e -> check'expr ctx e
   | GETADDRESS e -> check'expr ctx e
   | PLAINADDR e -> check'expr ctx e

let check'field ctx (FIELD (pos, ty, name)) =
   try
      let oldpos = Types.StringMap.find name !(ctx.fields) in
      Pos.failat pos ("Redefinition of field " ^ name);
      Pos.failat oldpos ("Previous definition")
   with Not_found ->
      begin
         try
            let oldpos = Types.StringMap.find name !(ctx.constants) in
            Pos.warnat pos ("Field " ^ name ^ " shadows a constant");
            Pos.warnat oldpos ("Definition of the constant")
         with Not_found -> ()
      end;
      (* XXX should check that the type exists *)
      let _ = ty in
      ctx.fields := Types.StringMap.add name pos !(ctx.fields)

let check'member ctx m = match m with
     ADDR f -> check'field ctx f
   | ADDREXPR ae -> check'addrexpr ctx ae
   | SIZE (f, _bits) -> check'field ctx f
   | SIZEEXPR (e, _bits) -> check'expr ctx e
   | EQ f -> check'field ctx f
   | REG f -> check'field ctx f

let optrequirecap ctx pos how optname =
   match optname with
        None -> ()
      | Some name -> try
           let _ = Types.StringMap.find name !(ctx.caps) in
           () (* ok *)
        with Not_found ->
           Pos.failat pos (how ^ " " ^ name ^ ": does not exist")

let check'cap ctx {
	   name; definedat;
	   generalequality; from; fromself;
	   (*multiretype;*)
	   (*abstract;*)
	   inherit_;
	   members;
	} =
   try
      let oldpos = Types.StringMap.find name !(ctx.caps) in
      Pos.failat definedat ("Redefinition of cap " ^ name);
      Pos.failat oldpos ("Previous definition")
   with Not_found ->
      (*
       * Hamlet's parser tries to enforce all these checks
       * syntactically, so if you do something wrong you get
       * "parse error".
       *)
      begin
      match generalequality, from, fromself with
           Some _, Some _, _
         | Some _, _, true ->
              Pos.failat definedat ("May not use 'is_*_copy' with 'from'")
         | _, _, _ -> ()
      end;
      optrequirecap ctx definedat "from" from;
      optrequirecap ctx definedat "inherit" inherit_;
      (*
       * Apparently not true. Hamlet's own parser requires that you
       * have a block of members if you don't inherit from something,
       * but it can be {}. That is silly...
       *)
(*
      if inherit_ = None then begin
         if members = [] then
            Pos.failat definedat ("Must have at least one field")
      end;
*)
      (* now check the members *)
      ctx.fields := Types.StringMap.empty;
      List.iter (check'member ctx) members;
      ctx.caps := Types.StringMap.add name definedat !(ctx.caps)

let check (defs, caps) =
   let ctx = newctx () in
   List.iter (check'def ctx) defs;
   List.iter (check'cap ctx) caps;
   Util.checkfail ()
