/**
 * \file
 * \brief ARM architecture initialization
 */

/*
 * Copyright (c) 2007, 2008, ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Haldeneggsteig 4, CH-8092 Zurich. Attn: Systems Group.
 */

#ifndef INIT_H
#define INIT_H

#ifndef __ASSEMBLER__

// #include <boot_protocol.h>

#include <barrelfish_kpi/mips_core_data.h>

/*
 * \brief Main entry point to C from boot.S
 */
void arch_init( struct mips_core_data *boot_core_data);

/*
 * Second-stage startup
 */
extern void mips_kernel_startup(void) __attribute__((noreturn));

#endif // __ASSEMBLER__

#endif // INIT_H
