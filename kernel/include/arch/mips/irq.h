/*
 * Copyright (c) 2010, ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Haldeneggsteig 4, CH-8092 Zurich. Attn: Systems Group.
 */

#ifndef KERNEL_ARCH_MIPS_IRQ_H
#define KERNEL_ARCH_MIPS_IRQ_H

/*MISSING something here*/
#define NUM_INTR                (128+32)

/// Size of hardware IRQ dispatch table == #NIDT - #NEXCEPTIONS exceptions
#define NDISPATCH               (NUM_INTR)
#endif // KERNEL_ARCH_MIPS_IRQ_H
