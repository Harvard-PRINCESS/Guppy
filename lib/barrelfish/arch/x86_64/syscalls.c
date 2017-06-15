/**
 * \file
 * \brief User-side system call implementation
 */

/*
 * Copyright (c) 2007, 2008, 2009, 2010, ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Haldeneggsteig 4, CH-8092 Zurich. Attn: Systems Group.
 */

#include <barrelfish/barrelfish.h>
#include <barrelfish/caddr.h>
#include <barrelfish/dispatch.h>
#include <barrelfish/syscall_arch.h>

/* For documentation on system calls see include/barrelfish/syscalls.h
 */

uint64_t sys_get_absolute_time(void)
{
    struct sysret r = syscall1(SYSCALL_GET_ABS_TIME);
    assert(err_is_ok(r.error));
    return r.value;
}
