/**
 * \file
 * \brief Arch specific CPU declarations
 */

/*
 * Copyright (c) 2010, ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Haldeneggsteig 4, CH-8092 Zurich. Attn: Systems Group.
 */

#ifndef ARCH_MIPS_BARRELFISH_KPI_CPU_H
#define ARCH_MIPS_BARRELFISH_KPI_CPU_H

/// This CPU supports lazy FPU context switching?
// XXX pursuant to dholland comment, MIPS actually does
// but until we have to deal with FPU stuff I will want
// to not touch that machdep part of dispatcher stuff
#undef FPU_LAZY_CONTEXT_SWITCH

#endif