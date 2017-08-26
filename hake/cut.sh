cat /dev/null > Makefile.new

# pull help-boot
grep "\.PHONY: help-boot" -A 2 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new

# pull sys161_mips
grep "\.PHONY: sys161_mips" -A 2 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new

# pull mips_sys161_image (sys161_mips depend)
grep "mips_sys161_image :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new

### START boot_sys161
# pull boot_sys161 (mips_sys161_image depend)
grep "boot_sys161 :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new

# pull mips/kernel/arch/mips/boot_driver.o
grep "\./mips/kernel/arch/mips/boot_driver\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
# pull mips/kernel/arch/mips/cache-mips161.o
grep "\./mips/kernel/arch/mips/cache-mips161\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
# pull mips/kernel/arch/mips/exception-mips1.o
grep "\./mips/kernel/arch/mips/exception-mips161\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
# pull mips/kernel/arch/mips/start.o
grep "\./mips/kernel/arch/mips/start\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new

# pull mips/kernel/boot_sys161.lds
grep "\./mips/kernel/boot_sys161\.lds :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new

# pull mips/kernel/logging.o
grep "\./mips/kernel/logging\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
# pull mips/kernel/memset.o
grep "\./mips/kernel/memset\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
# pull mips/kernel/printf.o
grep "\./mips/kernel/printf\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
# pull mips/kernel/stdlib.o
grep "\./mips/kernel/stdlib\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
# pull mips/kernel/string.o
grep "\./mips/kernel/string\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new

# pull mips/lib/libgetopt.a
grep "\./mips/lib/libgetopt\.a :" -A 2 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
grep "\./mips/lib/getopt/_for_lib_getopt/getopt\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new

# pull mips/lib/libmdb_kernel.a
grep "\./mips/lib/libmdb_kernel\.a :" -A 2 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
grep "\./mips/capabilities/cap_predicates\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
grep "\./mips/lib/mdb/_for_lib_mdb_kernel/mdb\.o :" -A 1 Makefile  >> Makefile.new
echo -e "\n" >> Makefile.new
grep "\./mips/lib/mdb/_for_lib_mdb_kernel/mdb_tree\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new

# pull mips/lib/libcompiler-rt.a
# lots of parts
grep "\./mips/lib/compiler-rt/.*\.o :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
grep "\./mips/lib/compiler-rt/libcompiler-rt\.a :" -A 2 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
### DONE boot_sys161

### START tools/bin/mips_bootimage
# pull tools/bin/mips_bootimage (mips_sys161_image depend)
grep "\.tools\/bin\/mips_bootimage :" -A 1 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new

# pull tools/lib/libgrubmenu.a (tools/bin/mips_bootimage depend)
# actually pulling everything from the multiboot Hakefile
grep "From: lib\/multiboot\/Hakefile" -A 6 Makefile >> Makefile.new
echo -e "\n" >> Makefile.new
### DONE tools/bin/mips_bootimage

### START simple-init
# pull mips/sbin/simple-init (mips_sys161_image depend)
#grep "\./mips/sbin/simple-init :" -A 1 Makefile >> Makefile.new
#echo -e "\n" >> Makefile.new

# pull mips/sbin/simple-init.full
#grep "\./mips/sbin/simple-init\.full :" -A 1 Makefile >> Makefile.new
#echo -e "\n" >> Makefile.new

# pull mips/lib/libelf.a
# pull mips/lib/libmm.a
# pull mips/lib/libspawndomain.a
# pull mips/lib/libtrace.a
# pull mips/usr/simple-init/_for_app_simple-init/init.o
# pull mips/errors/errno.o
# pull mips/lib/crt0.o
# pull mips/lib/crtbegin.o
# pull mips/lib/crtend.o
# pull mips/lib/libbarrelfish.a
# pull mips/lib/libcollections.a
# pull mips/lib/libcompiler-rt.a
# pull mips/lib/libnewlib.a
# pull mips/lib/liboctopus_parser.a
# pull mips/lib/libterm_client.a
### DONE simple-init
# TODO


# DONE EVERYTHING

# pull directories depend
grep "\.PHONY: directories" -A 5 Makefile >> Makefile.new

# sanitize grep outputs
sed -i -e "s/^--$/\n/" Makefile.new

# strip extraneous depends
sed -i -e "s#\./mips/sbin/simple-init.debug##" Makefile.new
sed -i -e "s#[a-z./_]*asmoffsets\.h ##" Makefile.new
sed -i -e "s#[a-z./_]*capbits\.h ##" Makefile.new
sed -i -e "s#[a-z./_]*errno\.h ##" Makefile.new
sed -i -e "s#[a-z./_]*trace_defs\.h ##" Makefile.new
