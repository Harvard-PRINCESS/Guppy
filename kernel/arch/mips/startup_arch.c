// #include <dispatch.h>
//#include <barrelfish_kpi/mips_core_data.h>

void mips_kernel_startup(void)
{
    // mips_kernel_startup entered \n");
    // struct dcb *init_dcb;

    // struct multiboot_info *mb = (struct multiboot_info *)core_data->multiboot_header;
    // size_t max_addr = max(multiboot_end_addr(mb),
    //                       (uintptr_t)&kernel_final_byte);

    // /* Initialize the location to allocate phys memory from */
    // bsp_init_alloc_addr = mem_to_local_phys(max_addr);

    /* Initial KCB was allocated by the boot driver. */
    //assert(kcb_current);

    // Bring up init
    //init_dcb = spawn_init(SIMPLE_INIT_MODULE_NAME);


    /* XXX - this really shouldn't be necessary. */
    //MSG("Trying to enable interrupts\n"); 
    // __asm volatile ("CPSIE aif"); 
    //MSG("Done enabling interrupts\n");

    /* printf("HOLD BOOTUP - SPINNING\n"); */
    /* while (1); */
    /* printf("THIS SHOULD NOT HAPPEN\n"); */

    // enable interrupt forwarding to cpu
    // FIXME: PS: enable this as it is needed for multicore setup.
    //gic_cpu_interface_enable();

    // Should not return
    // MSG("Calling dispatch from arm_kernel_startup, start address is=%"PRIxLVADDR"\n",
    //       get_dispatcher_shared_arm(init_dcb->disp)->enabled_save_area.named.r0);
    //dispatch(init_dcb);
    //panic("Error spawning init!");

    volatile unsigned int i = 0;
    while (1) {
        i++;
    }




}
