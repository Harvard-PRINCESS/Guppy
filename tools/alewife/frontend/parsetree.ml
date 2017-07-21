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

type def = DEFINE of Pos.pos * string * int

type expr =
     NAME of Pos.pos * string
   | ADD of Pos.pos * expr * expr

type addrexpr =
     MEMTOPHYS of expr
   | GETADDRESS of expr
   | PLAINADDR of expr

type field = FIELD of Pos.pos * string(*type*) * string(*name*)

type member =
     ADDR of field
   | ADDREXPR of addrexpr
   | SIZE of field * bool(*isbits*)
   | SIZEEXPR of expr * bool(*isbits*)
   | EQ of field
   | REG of field

type cap = {
   name: string;
   definedat: Pos.pos;
   generalequality: bool option;
   from: string option;
   fromself: bool;
   multiretype: bool;
   abstract: bool;
   inherit_: string option;
   members: member list;
}
