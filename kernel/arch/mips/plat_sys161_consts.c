/**
 * \file
 * \brief Platform code for the Cortex-A9 processors on TI OMAP44xx SoCs.
 */

/*
 * Copyright (c) 2009-2016 ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Universitaetstr 6, CH-8092 Zurich. Attn: Systems Group.
 */

//#include <kernel.h>

#include <barrelfish/types.h>

/* RAM starts at 2G (2 ** 31) on the Pandaboard */
/* XXX - MMAP */
lpaddr_t phys_memory_start= 0x80000000;

