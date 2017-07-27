
#ifndef DISPATCH_ARCH_H
#define DISPATCH_ARCH_H

#include <barrelfish_kpi/dispatcher_shared_arch.h>
#include <barrelfish_kpi/dispatcher_shared_target.h>
#include <capabilities.h>

static inline struct dispatcher_shared_arm*
get_dispatcher_shared_arm_cap(struct capability* disp_cap, dispatcher_handle_t disp)
{
    dispatcher_handle_t handle = local_phys_to_mem(disp_cap->u.frame.base);
    assert (handle == disp);
    return get_dispatcher_shared_arm(handle);
}
#endif