#include <barrelfish/types.h>
#include <offsets.h>
#include <multiboot.h>
#include <barrelfish_kpi/mips_core_data.h>
#include <string.h>

struct mips_core_data boot_core_data __attribute__((section(".boot")));
/*
struct boot_arguments {
    void *pointer;
    void *cpu_driver_entry;
} boot_arguments= { (void *)0xbadc0fee, (void*) 0 };
*/
extern int multiboot_pointer_linker;
extern int cpu_driver_entry_linker;

/* There is only one copy of the global locks, which is allocated alongside
 * the BSP kernel.  All kernels have their pointers set to the BSP copy. */
static struct global bsp_global __attribute__((section(".boot")));
struct global *global= &bsp_global;

/* The BSP core's KCB is allocated here.  Application cores will have theirs
 * allocated at user level. */
struct kcb bsp_kcb __attribute__((section(".boot")));

struct mips_core_data boot_core_data __attribute__((section(".boot")));

void switch_and_jump(void *cpu_driver_entry, lvaddr_t boot_pointer);

void boot(void *multiboot_pointer, void *cpu_driver_entry) {
	// multiboot_pointer --> bootdriver pointer 
	// cpu_driver_entry --> bootdriver pointer
    // XXX needs to get multiboot structure
    // XXX needs to get linked in by static bootloader
    // XXX needs to longjump to cpu_start or arch_init or something

    // other things this function might do:
    // - set up the serial port
    // - set up spinlocks
    // - CPU ID?
    // - set up page tables for the kernel (it's a 1-1 mapping, but...)


    /* Grab the multiboot header, so we can find our command line.  Note that
     * we're still executing with physical addresses, to we need to convert
     * the pointer back from the kernel-virtual address that the CPU driver
     * will use. */

    // multiboot_pointer is boot string under sys161
    // but we must ignore it
    // if you're seeing 0xdeadbeef here, you messed up your build
    multiboot_pointer = &multiboot_pointer_linker;
    cpu_driver_entry = &cpu_driver_entry_linker;

    struct multiboot_info *mbi= 
    	(struct multiboot_info *) mem_to_local_phys((lvaddr_t)multiboot_pointer);

    /* If there's no commandline passed, panic on port 0. */
    if(!(mbi->flags & MULTIBOOT_INFO_FLAG_HAS_CMDLINE)) {
        serial_early_init(0);
        //panic("No commandline arguments.\n");
    }
      
    /* Parse the commandline, to find which console port to connect to. */
    init_bootargs();
    const char *cmdline= (const char *)mbi->cmdline;
    parse_commandline(cmdline, bootargs);

    /* Initialise the serial port driver using the physical address of the
     * port, so that we can start printing before we enable the MMU. */
    serial_early_init(serial_console_port);

    //no need for spinlock initialization in sys161

    /* Get the memory map. */
    if(!(mbi->flags & MULTIBOOT_INFO_FLAG_HAS_MMAP))
        panic("No memory map.\n");
    struct multiboot_mmap *mmap= (struct multiboot_mmap *)mbi->mmap_addr;
    if(mbi->mmap_length == 0) panic("Memory map is empty.\n");

    /* Fill in the boot data structure for the CPU driver. */
    /* We need to pass in anything we've allocated. */
    boot_core_data.multiboot_header= local_phys_to_mem((lpaddr_t)mbi);
    boot_core_data.global=           local_phys_to_mem((lpaddr_t)&bsp_global);
    boot_core_data.kcb=              local_phys_to_mem((lpaddr_t)&bsp_kcb);
    //boot_core_data.target_bootrecs=  local_phys_to_mem((lpaddr_t)&boot_records);

    memcpy((void*) &boot_core_data.kernel_module,
           (void *)mbi->mods_addr,
           sizeof(struct multiboot_modinfo));
    boot_core_data.cmdline= local_phys_to_mem(mbi->cmdline);

    /* Relocate the boot data pointer for the CPU driver. */
    lvaddr_t boot_pointer= local_phys_to_mem((lpaddr_t)&boot_core_data);

    // MIPS doesn't need create kernel page tables.

    switch_and_jump(cpu_driver_entry, boot_pointer);
}



void switch_and_jump(void *cpu_driver_entry, lvaddr_t boot_pointer) {
   
    /* Long jump to the CPU driver entry point, passing the kernel-virtual
     * address of the boot_core_data structure. */
    __asm("move $a0, %[pointer]\n"
          "jr %[jump_target]\n"
          "nop\n"
          : /* No outputs */
          : [jump_target] "r"(cpu_driver_entry),
            [pointer]     "r"(boot_pointer)
          : "a0");

    //panic("Shut up GCC, I'm not returning.\n");
}
