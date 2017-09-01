#!/usr/bin/env bash

# clear pre-existing Makefile.new
cat /dev/null > Makefile.new


# entries to pull from the makefile: it'll be
# grep [left] -A [num] Makefile >> Makefile.new
declare -a entries=(
    # pull help-boot
    "\.PHONY: help-boot" 2

    # pull sys161_mips
    "\.PHONY: sys161_mips" 2

    # pull mips_sys161_image (sys161_mips depend)
    "mips_sys161_image :" 1

    ### START boot_sys161 section
        # pull boot_sys161 (mips_sys161_image depend)
        "boot_sys161 :" 1

        # pull mips/kernel/arch/mips/boot_driver.o
        "\./mips/kernel/arch/mips/boot_driver\.o :" 1

        # pull mips/kernel/arch/mips/cache-mips161.o
        "\./mips/kernel/arch/mips/cache-mips1\.o :" 1
        # pull mips/kernel/arch/mips/exception-mips1.o
        "\./mips/kernel/arch/mips/exception-mips1\.o :" 1
        # pull mips/kernel/arch/mips/start.o
        "\./mips/kernel/arch/mips/start\.o :" 1
        # pull mips/kernel/boot_sys161.lds
        "\./mips/kernel/boot_sys161\.lds :" 1
        # pull mips/kernel/logging.o
        #"\./mips/kernel/logging\.o :" 1
        # pull mips/kernel/memset.o
        "\./mips/kernel/memset\.o :" 1
        # pull mips/kernel/printf.o
        #"\./mips/kernel/printf\.o :" 1
        # pull mips/kernel/stdlib.o
        "\./mips/kernel/stdlib\.o :" 1
        # pull mips/kernel/string.o
        "\./mips/kernel/string\.o :" 1

        # pull mips/lib/libgetopt.a
        "\./mips/lib/libgetopt\.a :" 2
        "\./mips/lib/getopt/_for_lib_getopt/getopt\.o :" 1

        # pull mips/lib/libmdb_kernel.a
        "\./mips/lib/libmdb_kernel\.a :" 2
        "\./mips/capabilities/cap_predicates\.o :" 1
        "\./mips/lib/mdb/_for_lib_mdb_kernel/mdb\.o :" 1
        "\./mips/lib/mdb/_for_lib_mdb_kernel/mdb_tree\.o :" 1

        # pull mips/lib/libcompiler-rt.a
        # lots of parts
        "\./mips/lib/compiler-rt/.*\.o :" 1
        "\./mips/lib/compiler-rt/libcompiler-rt\.a :" 2
    ### DONE boot_sys161

    ### START tools/bin/mips_bootimage section
        # pull tools/bin/mips_bootimage (mips_sys161_image depend)
        "\.tools\/bin\/mips_bootimage :" 1

        # pull tools/lib/libgrubmenu.a (tools/bin/mips_bootimage depend)
        # actually pulling everything from the multiboot Hakefile
        "From: lib\/multiboot\/Hakefile" 6
    ### DONE tools/bin/mips_bootimage

    # TODO hamlet build

    # TODO
    ### START simple-init
        # pull mips/sbin/simple-init (mips_sys161_image depend)
        "\./mips/sbin/simple-init :" 1

        # pull mips/sbin/simple-init.full
        "\./mips/sbin/simple-init\.full :" 1

        # pull mips/lib/libelf.a
        "\./mips/lib/libelf\.a :" 2
        "\./mips/lib/mdb/_for_lib_elf/elf\.o :" 1
        "\./mips/lib/mdb/_for_lib_elf/elf32\.o :" 1
        "\./mips/lib/mdb/_for_lib_elf/elf64\.o :" 1
        # pull mips/lib/libmm.a
        "\./mips/lib/libmm\.a :" 2
        "\./mips/lib/mdb/_for_lib_mm/mm\.o :" 1
        "\./mips/lib/mdb/_for_lib_mm/slot_alloc\.o :" 1
        # pull mips/lib/libspawndomain.a
        "\./mips/lib/libspawndomain\.a :" 2
        "\./mips/lib/mdb/_for_lib_spawndomain/mm\.o :" 1
        "\./mips/lib/mdb/_for_lib_spawndomain/slot_alloc\.o :" 1
        # pull mips/lib/liboctopus.a
        "\./mips/lib/liboctopus\.a :" 2
        "\./mips/lib/liboctopus_parser\.a :" 2
        "\./mips/lib/libthc\.a :" 2
        "\./mips/lib/octopus/_for_lib_octopus/client/.*\.o :" 1
        "\./mips/lib/octopus/_for_lib_octopus/octopus_flounder_bindings\.o :" 1
        "\./mips/lib/octopus/_for_lib_octopus/octopus_flounder_extra_bindings\.o :" 1
        "\./mips/lib/octopus/_for_lib_octopus/octopus_thc\.o :" 1


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

)


# Makefile put loop
for i in $(eval echo {0..$((${#entries[@]}-1))..2})
do
    grep "${entries[$i]}" -A ${entries[$(($i+1))]} Makefile >> Makefile.new
    echo -e "\n" >> Makefile.new
done


# FINAL CLEANUP STEPS:

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

