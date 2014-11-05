/**
 * \file
 * \brief Boot driver for x86-64 CPUs
 */
/*
 * Copyright (c) 2013, ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Haldeneggsteig 4, CH-8092 Zurich. Attn: Systems Group.
 */

#include "coreboot.h"

#include <target/x86/barrelfish_kpi/coredata_target.h>
#include <target/x86_32/barrelfish_kpi/paging_target.h>
#include <target/x86_64/barrelfish_kpi/paging_target.h>

// From kernels start_aps.c
#include <kernel.h>
#include <arch/x86/apic.h>
#include <arch/x86/start_aps.h>
#include <x86.h>
#include <arch/x86/cmos.h>
#include <init.h>
#include <dev/xapic_dev.h>
#include <target/x86_64/offsets_target.h>

#define MON_URPC_CHANNEL_LEN  (32 * UMP_MSG_BYTES)


struct elf_allocate_state {
    void *vbase;
    genvaddr_t elfbase;
};

/**
 * Start_ap and start_ap_end mark the start end the
 * end point of the assembler startup code to be copied
 */
extern uint64_t x86_64_start_ap;
extern uint64_t x86_64_start_ap_end;
extern uint64_t x86_64_init_ap_absolute_entry;
extern uint64_t x86_64_init_ap_wait;
extern uint64_t x86_64_init_ap_lock;
extern uint64_t x86_64_start;
extern uint64_t x86_64_init_ap_global;
extern uint64_t x86_64_init_ap_dispatch;

volatile uint64_t *dispatch[255];
volatile uint64_t *ap_dispatch;
extern coreid_t my_arch_id;
extern struct capref kernel_cap;
extern uint64_t end;

static errval_t elfload_allocate(void *state, genvaddr_t base,
                                         size_t size, uint32_t flags,
                                         void **retbase)
{
    struct elf_allocate_state *s = state;

    *retbase = (char *)s->vbase + base - s->elfbase;
    return SYS_ERR_OK;
}

/**
 * \brief Spawn a new core.
 *
 * \param core_id    APIC ID of the core to try booting
 * \param cpu_type   Type of core to boot
 * \param entry      Kernel entry point in physical memory
 */
static inline errval_t
invoke_spawn_core(coreid_t core_id, enum cpu_type cpu_type,
                  forvaddr_t entry)
{

    /*struct capref task_cap_kernel;
    task_cap_kernel.cnode = cnode_task;
    task_cap_kernel.slot = TASKCN_SLOT_KERNELCAP;

    return cap_invoke4(kernel_cap, KernelCmd_Spawn_core, core_id, cpu_type,
                       entry).error;*/
}

static char* get_binary_path(char* fmt, char* binary_name)
{
    assert (binary_name != NULL);
    assert (fmt != NULL);

    int length = snprintf(NULL, 0, fmt, binary_name);

    char* binary = malloc(length+1); // TODO(gz): Free this
    snprintf(binary, length+1, fmt, binary_name);

    return binary;
}

errval_t get_architecture_config(enum cpu_type type,
                                 genpaddr_t *arch_page_size,
                                 const char **monitor_binary,
                                 const char **cpu_binary)
{
    extern char* cmd_kernel_binary;
    extern char* cmd_monitor_binary;

    switch (type) {
    case CPU_X86_64:
    {
        *arch_page_size = X86_64_BASE_PAGE_SIZE;
        *monitor_binary = (cmd_kernel_binary == NULL) ?
                        "/x86_64/sbin/monitor" :
                        get_binary_path("/x86_64/sbin/%s", cmd_monitor_binary);
        *cpu_binary = (cmd_kernel_binary == NULL) ?
                        "/x86_64/sbin/cpu" :
                        get_binary_path("/x86_64/sbin/%s", cmd_kernel_binary);
    }
        break;

    case CPU_X86_32:
        *arch_page_size = X86_32_BASE_PAGE_SIZE;
        *monitor_binary = "x86_32/sbin/monitor";
        *cpu_binary = "x86_32/sbin/cpu";
        break;

    default:
        return SPAWN_ERR_UNKNOWN_TARGET_ARCH;
    }

    return SYS_ERR_OK;
}

/**
 * \brief Boot a app core of x86_64 type
 *
 * The processors are started by a sequency of INIT and STARTUP IPIs
 * which are sent by this function.
 * CMOS writes to the shutdown status byte are used to execute
 * different memory locations.
 *
 * \param core_id   APIC ID of the core to try booting
 * \param entry     Entry address for new kernel in the destination
 *                  architecture's lvaddr_t given in genvaddr_t
 *
 * \returns Zero on successful boot, non-zero (error code) on failure
 */
int start_aps_x86_64_start(uint8_t core_id, genvaddr_t entry)
{
    DEBUG("%s:%d: start_aps_x86_64_start\n", __FILE__, __LINE__);

    // Copy the startup code to the real-mode address
    uint8_t *real_src = (uint8_t *) &x86_64_start_ap;
    uint8_t *real_end = (uint8_t *) &x86_64_start_ap_end;

    struct capref bootcap;
    struct acpi_rpc_client* acl = get_acpi_rpc_client();
    errval_t error_code;
    errval_t err = acl->vtbl.mm_realloc_range_proxy(acl, 16, 0x0,
                                                    &bootcap, &error_code);
    if (err_is_fail(err)) {
        USER_PANIC_ERR(err, "mm_alloc_range_proxy failed.");
    }
    if (err_is_fail(error_code)) {
        USER_PANIC_ERR(error_code, "mm_alloc_range_proxy return failed.");
    }

    void* real_base;
    err = vspace_map_one_frame(&real_base, 1<<16, bootcap, NULL, NULL);
    uint8_t* real_dest = (uint8_t*)real_base + X86_64_REAL_MODE_LINEAR_OFFSET;

/*
    DEBUG("%s:%d: X86_64_REAL_MODE_LINEAR_OFFSET=%p\n", __FILE__, __LINE__, (void*)X86_64_REAL_MODE_LINEAR_OFFSET);
    DEBUG("%s:%d: real_dest=%p\n", __FILE__, __LINE__, real_dest);
    DEBUG("%s:%d: real_src=%p\n", __FILE__, __LINE__, real_src);
    DEBUG("%s:%d: real_end=%p\n", __FILE__, __LINE__, real_end);
    DEBUG("%s:%d: size=%lu\n", __FILE__, __LINE__, (uint64_t)real_end-(uint64_t)real_src);
*/

    memcpy(real_dest, real_src, real_end - real_src);

    /* Pointer to the entry point called from init_ap.S */
    volatile uint64_t *absolute_entry_ptr = (volatile uint64_t *)
                                            ((
                                             (lpaddr_t) &x86_64_init_ap_absolute_entry -
                                             (lpaddr_t) &x86_64_start_ap
                                            )
                                            +
                                            real_dest);
    //copy the address of the function start (in boot.S) to the long-mode
    //assembler code to be able to perform an absolute jump
    *absolute_entry_ptr = entry;

    // pointer to the shared global variable amongst all kernels
    volatile uint64_t *ap_global = (volatile uint64_t *)
                                   ((
                                    (lpaddr_t) &x86_64_init_ap_global -
                                    (lpaddr_t) &x86_64_start_ap
                                   )
                                   + real_dest);


    genpaddr_t global;
    err = invoke_get_global_paddr(kernel_cap, &global);
    if (err_is_fail(err)) {
        DEBUG_ERR(err, "invoke spawn core");
        return err_push(err, MON_ERR_SPAWN_CORE);
    }
    *ap_global = (uint64_t)(genpaddr_t)global;

    // pointer to the pseudo-lock used to detect boot up of new core
    volatile uint32_t *ap_wait = (volatile uint32_t *)
                                         ((lpaddr_t) &x86_64_init_ap_wait -
                                         ((lpaddr_t) &x86_64_start_ap) +
                                         real_dest);

    // pointer to the pseudo-lock that is set before dispatch,
    // to measure time it takes to update the kernel
    ap_dispatch = (volatile uint64_t *)
                   ((lpaddr_t) &x86_64_init_ap_dispatch -
                   ((lpaddr_t) &x86_64_start_ap) +
                    real_dest);
    dispatch[core_id] = ap_dispatch;
    *ap_dispatch = 0;

    // Pointer to the lock variable in the realmode code
    volatile uint8_t *ap_lock = (volatile uint8_t *)
                                        ((lpaddr_t) &x86_64_init_ap_lock -
                                        ((lpaddr_t) &x86_64_start_ap) +
                                        real_dest);

    *ap_wait = AP_STARTING_UP;

    end = bench_tsc();
    err = invoke_send_init_ipi(core_id);
    if (err_is_fail(err)) {
        DEBUG_ERR(err, "invoke send init ipi");
        return err;
    }

    err = invoke_send_start_ipi(core_id, entry);
    if (err_is_fail(err)) {
        DEBUG_ERR(err, "invoke sipi");
        return err;
    }

    /*err = invoke_send_start_ipi(core_id, entry);
    if (err_is_fail(err)) {
        DEBUG_ERR(err, "invoke sipi");
        return err;
    }*/



    //give the new core a bit time to start-up and set the lock
    for (uint64_t i = 0; i < STARTUP_TIMEOUT; i++) {
        if (*ap_lock != 0) {
            break;
        }
    }

    // If the lock is set, the core has been started, otherwise assume, that
    // a core with this APIC ID doesn't exist.
    if (*ap_lock != 0) {
        while (*ap_wait != AP_STARTED);
        trace_event(TRACE_SUBSYS_KERNEL, TRACE_EVENT_KERNEL_CORE_START_REQUEST_ACK, core_id);
        *ap_lock = 0;
        return 0;
    }

    assert(!"badness");
    return -1;
}


/**
 * Allocates memory for kernel binary.
 *
 * For x86, the app kernel can only be loaded in the first 4GB
 * of memory. Further, it must not overlap the integer
 * boundaries, i.e. 0-1, 1-2, 2-3, or 3-4.
 *
 * Probably because we identity map this region during boot-phase
 * so we can't access anything higher. Not sure about overlap tough.
 */
static errval_t allocate_kernel_memory(lvaddr_t cpu_binary, genpaddr_t page_size,
                                       struct capref* cpu_memory_cap, size_t* cpu_memory,
                                       struct frame_identity* id)
{
    errval_t err;
#ifdef __scc__
    *cpu_memory = X86_32_BASE_PAGE_SIZE;
    err = frame_alloc_identify(cpu_memory_cap, *cpu_memory, cpu_memory, id);
    if (err_is_fail(err)) {
        return err_push(err, LIB_ERR_FRAME_ALLOC);
    }
#else
    *cpu_memory = elf_virtual_size(cpu_binary) + page_size;

    uint64_t old_minbase;
    uint64_t old_maxlimit;
    ram_get_affinity(&old_minbase, &old_maxlimit);
    DEBUG("%s:%d: \n", __FILE__, __LINE__);
    for (uint64_t minbase = 0, maxlimit = (uint64_t)1 << 30;
            minbase < (uint64_t)4 << 30;
            minbase += (uint64_t)1 << 30, maxlimit += (uint64_t)1 << 30) {

        ram_set_affinity(minbase, maxlimit);
        err = frame_alloc_identify(cpu_memory_cap, *cpu_memory, cpu_memory, id);
        if (err_is_fail(err)) {
            continue;
        } else {
            goto done;
        }
    }

    USER_PANIC("No memory in the first 4GB, cannot continue booting cores");

done:
    ram_set_affinity(old_minbase, old_maxlimit);
#endif

    return SYS_ERR_OK;
}

static errval_t relocate_cpu_binary(lvaddr_t cpu_binary,
                                    struct Elf64_Ehdr *cpu_head,
                                    struct elf_allocate_state state,
                                    struct frame_identity frameid,
                                    genpaddr_t arch_page_size)
{
    switch (cpu_head->e_machine) {
    case EM_X86_64: {
        struct Elf64_Shdr *rela, *symtab, *symhead =
            (struct Elf64_Shdr *)(cpu_binary + (uintptr_t)cpu_head->e_shoff);

        assert(cpu_head->e_shoff != 0);
        rela = elf64_find_section_header_type(symhead, cpu_head->e_shnum, SHT_RELA);
        assert(rela != NULL);
        symtab = elf64_find_section_header_type(symhead, cpu_head->e_shnum, SHT_DYNSYM);
        assert(symtab != NULL);
        elf64_relocate(frameid.base + arch_page_size, state.elfbase,
                       (struct Elf64_Rela *)(uintptr_t)(cpu_binary + rela->sh_offset),
                       rela->sh_size,
                       (struct Elf64_Sym *)(uintptr_t)(cpu_binary + symtab->sh_offset),
                       symtab->sh_size,
                       state.elfbase, state.vbase);
        break;
    }
    case EM_386: {
        struct Elf32_Ehdr *head32 = (struct Elf32_Ehdr *)cpu_binary;

        struct Elf32_Shdr *rel, *symtab, *symhead =
            (struct Elf32_Shdr *)(cpu_binary + (uintptr_t)head32->e_shoff);

        rel = elf32_find_section_header_type(symhead, head32->e_shnum, SHT_REL);
        assert(rel != NULL);
        symtab = elf32_find_section_header_type(symhead, head32->e_shnum,
                                                SHT_DYNSYM);
        assert(symtab != NULL);
        elf32_relocate(frameid.base + arch_page_size, state.elfbase,
                       (struct Elf32_Rel *)(uintptr_t)(cpu_binary + rel->sh_offset),
                       rel->sh_size,
                       (struct Elf32_Sym *)(uintptr_t)(cpu_binary + symtab->sh_offset),
                       symtab->sh_size,
                       state.elfbase, state.vbase);
        break;
    }
    default:
        return SPAWN_ERR_UNKNOWN_TARGET_ARCH;
    }

    return SYS_ERR_OK;
}

errval_t spawn_xcore_monitor(coreid_t coreid, int hwid,
                             enum cpu_type cpu_type,
                             const char *cmdline,
                             struct frame_identity urpc_frame_id,
                             struct capref kcb)
{
    uint64_t start = 0;
    const char *monitorname = NULL, *cpuname = NULL;
    genpaddr_t arch_page_size;
    errval_t err;

    err = get_architecture_config(cpu_type, &arch_page_size,
                                  &monitorname, &cpuname);
    assert(err_is_ok(err));

    DEBUG("loading kernel: %s\n", cpuname);
    DEBUG("loading 1st app: %s\n", monitorname);

    // compute size of frame needed and allocate it
    DEBUG("%s:%s:%d: urpc_frame_id.base=%"PRIxGENPADDR"\n",
           __FILE__, __FUNCTION__, __LINE__, urpc_frame_id.base);
    DEBUG("%s:%s:%d: urpc_frame_id.size=%d\n",
           __FILE__, __FUNCTION__, __LINE__, urpc_frame_id.bits);

    if (benchmark_flag) {
        start = bench_tsc();
    }
    static size_t cpu_binary_size;
    static lvaddr_t cpu_binary = 0;
    static genpaddr_t cpu_binary_phys;
    static const char* cached_cpuname = NULL;
    if (cpu_binary == 0) {
        cached_cpuname = cpuname;
        // XXX: Caching these for now, until we have unmap
        err = lookup_module(cpuname, &cpu_binary, &cpu_binary_phys,
                            &cpu_binary_size);
        if (err_is_fail(err)) {
            DEBUG_ERR(err, "Can not lookup module");
            return err;
        }
    }
    // Ensure caching actually works and we're
    // always loading same binary. If this starts to fail, get rid of caching.
    assert (strcmp(cached_cpuname, cpuname) == 0);

    static size_t monitor_binary_size;
    static lvaddr_t monitor_binary = 0;
    static genpaddr_t monitor_binary_phys;
    static const char* cached_monitorname = NULL;
    if (monitor_binary == 0) {
        cached_monitorname = monitorname;
        // XXX: Caching these for now, until we have unmap
        err = lookup_module(monitorname, &monitor_binary,
                            &monitor_binary_phys, &monitor_binary_size);
        if (err_is_fail(err)) {
            DEBUG_ERR(err, "Can not lookup module");
            return err;
        }
    }
    // Again, ensure caching actually worked (see above)
    assert (strcmp(cached_monitorname, monitorname) == 0);

    if (benchmark_flag) {
        bench_data->load = bench_tsc() - start;
        start = bench_tsc();
    }

    struct capref cpu_memory_cap;
    struct frame_identity frameid;
    size_t cpu_memory;
    err = allocate_kernel_memory(cpu_binary, arch_page_size,
                                 &cpu_memory_cap, &cpu_memory, &frameid);
    if (err_is_fail(err)) {
        DEBUG_ERR(err, "Can not allocate space for new app kernel.");
        return err;
    }

    err = cap_mark_remote(cpu_memory_cap);
    if (err_is_fail(err)) {
        DEBUG_ERR(err, "Can not mark cap remote.");
        return err;
    }

    void *cpu_buf_memory;
    err = vspace_map_one_frame(&cpu_buf_memory, cpu_memory, cpu_memory_cap,
                               NULL, NULL);
    if (err_is_fail(err)) {
        return err_push(err, LIB_ERR_VSPACE_MAP);
    }
    if (benchmark_flag) {
        bench_data->alloc_cpu = bench_tsc() - start;
        start = bench_tsc();
    }

    /* Chunk of memory to load monitor on the app core */
    struct capref spawn_memory_cap;
    struct frame_identity spawn_memory_identity;

    err = frame_alloc_identify(&spawn_memory_cap,
                               X86_CORE_DATA_PAGES * arch_page_size,
                               NULL, &spawn_memory_identity);
    if (err_is_fail(err)) {
        return err_push(err, LIB_ERR_FRAME_ALLOC);
    }

    err = cap_mark_remote(spawn_memory_cap);
    if (err_is_fail(err)) {
        DEBUG_ERR(err, "Can not mark cap remote.");
        return err;
    }
    if (benchmark_flag) {
        bench_data->alloc_mon = bench_tsc() - start;
        start = bench_tsc();
    }

    /* Load cpu */
    struct elf_allocate_state state;
    state.vbase = (char *)cpu_buf_memory + arch_page_size;
    assert(sizeof(struct x86_core_data) <= arch_page_size);
    state.elfbase = elf_virtual_base(cpu_binary);

    struct Elf64_Ehdr *cpu_head = (struct Elf64_Ehdr *)cpu_binary;
    genvaddr_t cpu_entry;

    err = elf_load(cpu_head->e_machine, elfload_allocate, &state,
                   cpu_binary, cpu_binary_size, &cpu_entry);
    if (err_is_fail(err)) {
        return err;
    }
    if (benchmark_flag) {
        bench_data->elf_load = bench_tsc() - start;
        start = bench_tsc();
    }

    err = relocate_cpu_binary(cpu_binary, cpu_head, state, frameid, arch_page_size);
    if (err_is_fail(err)) {
        DEBUG_ERR(err, "Can not relocate new kernel.");
        return err;
    }
    if (benchmark_flag) {
        bench_data->elf_reloc = bench_tsc() - start;
    }

    genvaddr_t cpu_reloc_entry = cpu_entry - state.elfbase
                                 + frameid.base + arch_page_size;
    /* Compute entry point in the foreign address space */
    forvaddr_t foreign_cpu_reloc_entry = (forvaddr_t)cpu_reloc_entry;

    /* Setup the core_data struct in the new kernel */
    struct x86_core_data *core_data = (struct x86_core_data *)cpu_buf_memory;
    switch (cpu_head->e_machine) {
    case EM_X86_64:
        core_data->elf.size = sizeof(struct Elf64_Shdr);
        core_data->elf.addr = cpu_binary_phys + (uintptr_t)cpu_head->e_shoff;
        core_data->elf.num  = cpu_head->e_shnum;
        break;
    case EM_386:
        core_data->elf.size = sizeof(struct Elf32_Shdr);
        struct Elf32_Ehdr *head32 = (struct Elf32_Ehdr *)cpu_binary;
        core_data->elf.addr = cpu_binary_phys + (uintptr_t)head32->e_shoff;
        core_data->elf.num  = head32->e_shnum;
        break;
    default:
        return SPAWN_ERR_UNKNOWN_TARGET_ARCH;
    }
    core_data->module_start = cpu_binary_phys;
    core_data->module_end   = cpu_binary_phys + cpu_binary_size;
    core_data->urpc_frame_base = urpc_frame_id.base;
    core_data->urpc_frame_bits = urpc_frame_id.bits;
    core_data->monitor_binary   = monitor_binary_phys;
    core_data->monitor_binary_size = monitor_binary_size;
    core_data->memory_base_start = spawn_memory_identity.base;
    core_data->memory_bits       = spawn_memory_identity.bits;
    core_data->src_core_id       = disp_get_core_id();
    core_data->src_arch_id       = my_arch_id;
    core_data->dst_core_id       = coreid;


    struct frame_identity fid;
    invoke_frame_identify(kcb, &fid);
    DEBUG("%s:%s:%d: fid.base is 0x%"PRIxGENPADDR"\n",
           __FILE__, __FUNCTION__, __LINE__, fid.base);
    core_data->kcb = (genpaddr_t) fid.base;

#ifdef CONFIG_FLOUNDER_BACKEND_UMP_IPI
    core_data->chan_id           = chanid;
#endif

    if (cmdline != NULL) {
        // copy as much of command line as will fit
        snprintf(core_data->kernel_cmdline, sizeof(core_data->kernel_cmdline),
                "%s %s", cpuname, cmdline);
        // ensure termination
        core_data->kernel_cmdline[sizeof(core_data->kernel_cmdline) - 1] = '\0';

        DEBUG("%s:%s:%d: %s\n", __FILE__, __FUNCTION__, __LINE__, core_data->kernel_cmdline);
    }

    /* Invoke kernel capability to boot new core */
    start_aps_x86_64_start(hwid, foreign_cpu_reloc_entry);

    /* Clean up */
    // XXX: Should not delete the remote caps?
    err = cap_destroy(spawn_memory_cap);
    if (err_is_fail(err)) {
        USER_PANIC_ERR(err, "cap_destroy failed");
    }
    err = vspace_unmap(cpu_buf_memory);
    if (err_is_fail(err)) {
        USER_PANIC_ERR(err, "vspace unmap CPU driver memory failed");
    }
    err = cap_destroy(cpu_memory_cap);
    if (err_is_fail(err)) {
        USER_PANIC_ERR(err, "cap_destroy failed");
    }

    return SYS_ERR_OK;
}
