
void boot(char *bootstring, void *multiboot_pointer_XXX) {
    // XXX needs to get multiboot structure
    // XXX needs to get linked in by static bootloader
    // XXX needs to longjump to cpu_start or arch_init or something

    // other things this function might do:
    // - set up the serial port
    // - set up spinlocks
    // - CPU ID?
    // - set up page tables for the kernel (it's a 1-1 mapping, but...)
}
