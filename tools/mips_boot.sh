#!/bin/sh

# --globalize-symbols=/dev/null
mips-harvard-os161-objcopy -G __start ./mips/sbin/boot_sys161.rel.o ./mips/sbin/boot_sys161.rel.local.o
mips-harvard-os161-objcopy -G asdf ./mips/sbin/cpu_sys161.rel.o ./mips/sbin/cpu_sys161.rel.local.o

mips-harvard-os161-ld -T ./mips/kernel/mips_sys161_image.lds -Ttext 0x80000000 -o mips_sys161_image ./mips/sbin/boot_sys161.rel.local.o ./mips/sbin/cpu_sys161.rel.local.o
