/*
 * Copyright (c) 2000, 2001, 2002, 2003, 2004, 2005, 2008, 2009
 *	The President and Fellows of Harvard College.
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

#include <regdefs.h>
#include <specialreg.h> // XXX move this?
#include <offsets.h>

   .set noreorder

   .text
   .globl __start

   .bss
   .align 8  // XXX should we set it to 8 or 4?


// This stack is used by the boot driver on every core - the CPU driver has
// its own stack on each core.  This means that two boot drivers shouldn't run
// simultaneously, unless and until we change this.
//XXX need to be position independent!
//XXX get the addr of boot_stack using position-independent code?
//XXX find example~
//beginning of the func, cpu load, save in stack and restore 
boot_stack:
   .space KERNEL_STACK_SIZE, 0
boot_stack_top:
   .section .text
   .type __start,@function
   .ent __start
   //.extern got_base

__start:
  //find the address of __start
  .set noreorder
  /*
  bal 1f
  nop //in delay slot

1: 
  // get address of __start
  addiu ra, ra, -8
  .cpload ra
*/
  //init kernel stack
   la sp, boot_stack_top
  //Load the GP register.
  //XXX should we set the value of _gp to got_base first?
  // la gp, got_base

   /*
    * We're all set up!
    * Fetch the copy of the bootstring as the argument, and call main.
    */
   j boot
   nop			/* in delay slot */

   .end __start
