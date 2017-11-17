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

#ifndef TARGET_ARM_BARRELFISH_KPI_DISPATCHER_SHARED_H
#define TARGET_ARM_BARRELFISH_KPI_DISPATCHER_SHARED_H

#include <barrelfish_kpi/dispatcher_shared.h>
// ELU XXX kpi shouldn't refer to barrelfish
#include <barrelfish/caddr.h>
#include <barrelfish/invocations_arch.h>

// REFACTORING CHANGE
struct dispatcher_shared_arm_arm{
	// MD part
    lvaddr_t    crit_pc_low;        ///< Critical section lower PC bound
    lvaddr_t    crit_pc_high;       ///< Critical section upper PC bound
    lvaddr_t    got_base;           ///< Global Offset Table base

    union registers_arm enabled_save_area;  ///< Enabled register save area
    union registers_arm disabled_save_area; ///< Disabled register save area
    union registers_arm trap_save_area;     ///< Trap register save area
};

///< Architecture specific kernel/user shared dispatcher struct
struct dispatcher_shared_arm {
	/*
	// MD part
    lvaddr_t    crit_pc_low;        ///< Critical section lower PC bound
    lvaddr_t    crit_pc_high;       ///< Critical section upper PC bound
    lvaddr_t    got_base;           ///< Global Offset Table base

    union registers_arm enabled_save_area;  ///< Enabled register save area
    union registers_arm disabled_save_area; ///< Disabled register save area
    union registers_arm trap_save_area;     ///< Trap register save area
	*/
	// POINTER HERE
	struct dispatcher_shared_arm_arm* disp_kpi_arm_arm;
	struct dispatcher_shared_generic* disp_kpi_generic;
	// MD part
    struct dispatcher_shared_arm_arm aa;
    // MI part
    struct dispatcher_shared_generic d; ///< Generic portion

};
/*
static inline struct dispatcher_shared_arm*
get_dispatcher_shared_arm(dispatcher_handle_t handle)
{
    return (struct dispatcher_shared_arm*)handle;
}

static inline struct dispatcher_shared_arm_arm*
get_dispatcher_shared_arm_arm(dispatcher_handle_t handle)
{
	struct dispatcher_shared_arm * disp_arm = (struct dispatcher_shared_arm*) handle;
    return &disp_arm->aa;
}

static inline struct dispatcher_shared_generic*
get_dispatcher_shared_generic(dispatcher_handle_t handle)
{
    struct dispatcher_shared_arm *disp_arm = (struct dispatcher_shared_arm*) handle;
    return &disp_arm->d;
}
*/

// REFACTORING CHANGE
// POINTER HERE
static inline struct dispatcher_shared_arm*
get_dispatcher_shared_arm(dispatcher_handle_t handle)
{
    struct dispatcher_shared_arm *disp = (struct dispatcher_shared_arm*) handle;
    disp->disp_kpi_arm_arm = &disp->aa;
    disp->disp_kpi_generic = &disp->d;
    return disp;
}

static inline struct dispatcher_shared_arm_arm*
get_dispatcher_shared_arm_arm(dispatcher_handle_t handle)
{
	struct dispatcher_shared_arm * disp = get_dispatcher_shared_arm(handle);
    return disp->disp_kpi_arm_arm;
}

static inline struct dispatcher_shared_generic*
get_dispatcher_shared_generic(dispatcher_handle_t handle)
{
    struct dispatcher_shared_arm *disp = get_dispatcher_shared_arm(handle);
    return disp->disp_kpi_generic;
}

/*

/// Dispatcher structure (including data accessed only by user code)
struct dispatcher_arm {
	//REFACTORING CHANGE HERE
	dispatcher_handle_t disp_arm_kpi;
	dispatcher_handle_t disp_generic;

    //struct dispatcher_shared_arm d;  ///< Shared (user/kernel) data. Must be first.
    //struct dispatcher_generic generic;   ///< User private data
    // Incoming LMP endpoints (buffers and receive cap pointers) follow ss
};

static inline struct dispatcher_shared_arm*
get_dispatcher_shared_arm(dispatcher_handle_t handle)
{
    struct dispatcher_arm *disp = (struct dispatcher_arm*)handle;
	return (struct dispatcher_shared_arm*) disp->disp_arm_kpi;
}

static inline struct dispatcher_shared_generic*
get_dispatcher_shared_generic(dispatcher_handle_t handle)
{
    struct dispatcher_arm *disp = (struct dispatcher_arm*)handle;
    struct dispatcher_shared_arm *disp_arm = (struct dispatcher_shared_arm*) disp->disp_arm_kpi;
    return &disp_arm->d;
}*/

#endif // TARGET_ARM_BARRELFISH_KPI_DISPATCHER_SHARED_H
