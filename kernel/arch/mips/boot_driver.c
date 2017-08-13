
void arch_init(char *bootstring, void *multiboot_pointer_XXX) {
   /*
    * Now, copy the exception handler code onto the first page of memory.
    */

   li a0, EXADDR_UTLB
   la a1, mips_utlb_handler
   la a2, mips_utlb_end
   sub a2, a2, a1
   jal memmove
   nop

   li a0, EXADDR_GENERAL
   la a1, mips_general_handler
   la a2, mips_general_end
   sub a2, a2, a1
   jal memmove
   nop

   /*
    * Flush the instruction cache to make sure the above changes show
    * through to instruction fetch.
    */
   jal mips_flushicache
   nop

   /*
    * Initialize the TLB.
    */
   jal tlb_reset
   nop

   /*
    * Set up the status register.
    *
    * The MIPS has six hardware interrupt lines and two software interrupts.
    * These are individually maskable in the status register. However, we
    * don't use this feature (for simplicity) - we only use the master
    * interrupt enable/disable flag in bit 0. So enable all of those bits
    * now and forget about them.
    *
    * XXX
    * The BEV bit in the status register, if set, causes the processor to
    * jump to a different set of hardwired exception handling addresses.
    * This is so that the kernel's exception handling code can be loaded
    * into RAM and that the boot ROM's exception handling code can be ROM.
    * This flag is normally set at boot time, and we need to be sure to
    * clear it.
    *
    * The KUo/IEo/KUp/IEp/KUc/IEc bits should all start at zero.
    *
    * We also want all the other random control bits (mostly for cache
    * stuff) set to zero.
    *
    * Thus, the actual value we write is CST_IRQMASK.
    */

   li  t0, CST_IRQMASK		/* get value */
   mtc0 t0, c0_status		/* set status register */

   /*
    * Load the CPU number into the PTBASE field of the CONTEXT
    * register. This is necessary to read from cpustacks[] and
    * cputhreads[] on trap entry from user mode. See further
    * discussions elsewhere.
    *
    * Because the boot CPU is CPU 0, we can just send 0.
    */
   mtc0 $0, c0_context
}

