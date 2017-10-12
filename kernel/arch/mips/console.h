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

#ifndef _GENERIC_CONSOLE_H_
#define _GENERIC_CONSOLE_H_

/*
 * Device data for the hardware-independent system console.
 *
 * devdata, send, and sendpolled are provided by the underlying
 * device, and are to be initialized by the attach routine.
 */

#define CONSOLE_INPUT_BUFFER_SIZE 32
// XXX: leave it empty here to make sure everything else go through
struct thread {};

struct threadlistnode {
	struct threadlistnode *tln_prev;
	struct threadlistnode *tln_next;
	struct thread *tln_self;
};

struct threadlist {
	struct threadlistnode tl_head;
	struct threadlistnode tl_tail;
	unsigned tl_count;
};

/* Wait channel. A wchan is protected by an associated, passed-in spinlock. */
struct wchan {
	const char *wc_name;		/* name for this channel */
	struct threadlist wc_threads;	/* list of waiting threads */
};

/*
 * Dijkstra-style semaphore.
 *
 * The name field is for easier debugging. A copy of the name is made
 * internally.
 */
struct semaphore {
        char *sem_name;
	struct wchan *sem_wchan;
	//struct spinlock sem_lock;
        volatile unsigned sem_count;
};

struct con_softc {
	/* initialized by attach routine */
	void *cs_devdata;
	void (*cs_send)(void *devdata, int ch);
	void (*cs_sendpolled)(void *devdata, int ch);

	/* initialized by config routine */
	struct semaphore *cs_rsem;
	struct semaphore *cs_wsem;
	unsigned char cs_gotchars[CONSOLE_INPUT_BUFFER_SIZE];
	unsigned cs_gotchars_head;	/* next slot to put a char in */
	unsigned cs_gotchars_tail;	/* next slot to take a char out */
};

/*
 * Functions called by lower-level drivers
 */
void con_input(/*struct con_softc*/ void *cs, int ch);
void con_start(/*struct con_softc*/ void *cs);

/*
 * Functions called by higher-level code
 *
 * putch/getch - see <lib.h>
 */
int config_con(struct con_softc *cs, int unit);

#endif /* _GENERIC_CONSOLE_H_ */
