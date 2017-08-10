/**
 * \file
 * \brief architecture-specific registers code
 */

/*
 * Copyright (c) 2010, ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Haldeneggsteig 4, CH-8092 Zurich. Attn: Systems Group.
 */

#ifndef ARCH_MIPS_BARRELFISH_KPI_REGISTERS_H
#define ARCH_MIPS_BARRELFISH_KPI_REGISTERS_H

#ifndef __ASSEMBLER__
#include <barrelfish_kpi/types.h> // for lvaddr_t
#endif

#ifndef __ASSEMBLER__

struct registers_mips {
    uint32_t vaddr;	/* coprocessor 0 vaddr register */
    uint32_t status;	/* coprocessor 0 status register */
    uint32_t cause;	/* coprocessor 0 cause register */
    uint32_t lo, hi;

    /* Saved register 31 (ra) */
    uint32_t ra;
    /* Saved register 1 (AT) */
    uint32_t at;

    /* Saved register 2 (v0) */
    uint32_t v0, v1;
    uint32_t a0, a1, a2, a3;
    uint32_t t0, t1, t2, t3;
    uint32_t t4, t5, t6, t7;
    uint32_t s0, s1, s2, s3;
    uint32_t s4, s5, s6, s7;
    uint32_t t8, t9;

    /* dummy (see exception-mips1.S comments) */
    uint32_t k0, k1;

    uint32_t gp;
    uint32_t sp;
    uint32_t s8;

    /* coprocessor 0 epc register */
    uint32_t epc;
};

STATIC_ASSERT_SIZEOF(struct registers_mips, 37 * 4);

///< Opaque handle for the register state
typedef union registers_mips arch_registers_state_t;

///< Opaque handle for the FPU register state
typedef void *arch_registers_fpu_state_t;

static inline void
registers_set_entry(arch_registers_state_t *regs, lvaddr_t entry)
{
    regs->epc = (uint32_t)entry;
}

static inline void
registers_set_param(arch_registers_state_t *regs, uint32_t param)
{
    regs->a0 = param;
}

static inline void
registers_get_param(arch_registers_state_t *regs, uintptr_t *param)
{
    *param = regs->a0;
}

static inline uint32_t
registers_get_ip(arch_registers_state_t *regs)
{
    return regs->epc;
}

static inline uint32_t
registers_get_sp(arch_registers_state_t *regs)
{
    return regs->sp;
}

#endif // __ASSEMBLER__

#endif // ARCH_MIPS_BARRELFISH_KPI_REGISTERS_H
