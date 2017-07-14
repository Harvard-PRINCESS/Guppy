/**
 * \file
 * \brief Architecture specific dispatcher structure private to the user
 */

/*
 * Copyright (c) 2010, ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Haldeneggsteig 4, CH-8092 Zurich. Attn: Systems Group.
 */

#ifndef ARCH_ARM_BARRELFISH_DISPATCHER_H
#define ARCH_ARM_BARRELFISH_DISPATCHER_H

#include <barrelfish_kpi/dispatcher_shared.h>
#include <barrelfish_kpi/dispatcher_shared_target.h>
#include <target/arm/barrelfish/dispatcher_target.h>

static inline struct dispatcher_generic*
get_dispatcher_generic(dispatcher_handle_t handle)
{
    struct dispatcher_arm *disp = (struct dispatcher_arm*)handle;
    return &disp->generic;
}
/*
//REFACTORING CHANGE HERE
static inline struct dispatcher_generic*
get_dispatcher_generic(dispatcher_handle_t handle)
{
    struct dispatcher_arm *disp = (struct dispatcher_arm*)handle;
	return (struct dispatcher_generic*) disp->disp_generic;
}
*/
static inline size_t get_dispatcher_size(void)
{
    return sizeof(struct dispatcher_arm);
}

#endif // ARCH_ARM_BARRELFISH_DISPATCHER_H
