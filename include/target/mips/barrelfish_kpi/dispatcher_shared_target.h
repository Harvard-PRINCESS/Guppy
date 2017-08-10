/**
 * \file
 * \brief Architecture specific dispatcher struct shared between kernel and user
 */

/*
 * Copyright (c) 2010, ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Haldeneggsteig 4, CH-8092 Zurich. Attn: Systems Group.
 */

#ifndef TARGET_MIPS_BARRELFISH_KPI_DISPATCHER_SHARED_H
#define TARGET_MIPS_BARRELFISH_KPI_DISPATCHER_SHARED_H

#include <barrelfish_kpi/dispatcher_shared.h>

///< Architecture specific kernel/user shared dispatcher struct
struct dispatcher_shared_mips {
    struct dispatcher_shared_generic d; ///< Generic portion

    lvaddr_t    crit_pc_low;        ///< Critical section lower PC bound
    lvaddr_t    crit_pc_high;       ///< Critical section upper PC bound
    lvaddr_t    got_base;           ///< Global Offset Table base

    struct registers_mips enabled_save_area;  ///< Enabled register save area
    struct registers_mips disabled_save_area; ///< Disabled register save area
    struct registers_mips trap_save_area;     ///< Trap register save area
};

static inline struct dispatcher_shared_mips*
get_dispatcher_shared_mips(dispatcher_handle_t handle)
{
    return (struct dispatcher_shared_mips*)handle;
}

#endif // TARGET_MIPS_BARRELFISH_KPI_DISPATCHER_SHARED_H
