/*
 * A static 'bootloader' for ARMv7 platforms.
 *
 * This tool loads and relocates the boot driver (into physical addresses) and
 * the CPU driver into kernel virtual.  It also constructs a multiboot image,
 * and places the lot into an ELF file with a single loadable segment.  Thus,
 * if this ELF file is passed to a simulator, or loaded onto a pandaboard, on
 * jumping to its start address, we're ready to go, just as if we'd been
 * started by a dynamic bootloader.
 *
 * Copyright (c) 2016, ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Universitaetstr. 6, CH-8092 Zurich. Attn: Systems Group.
 */

#include <sys/stat.h>
#include <sys/types.h>

#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <libelf.h>
#include <limits.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* We need to be able to parse menu.lst files, create multiboot images. */
#include "../../include/grubmenu.h"
#include "../../include/multiboot.h"

/* XXX - this should be taken from the kernel offsets.h. */
#define KERNEL_WINDOW 0x80000000
#define BASE_PAGE_SIZE (1<<12)

#undef DEBUG

#ifdef DEBUG
#define DBG(format, ...) printf(format, ## __VA_ARGS__)
#else
#define DBG(format, ...)
#endif

/* Keep physical addresses and kernel virtual addresses separated, as far as
 * possible. */
typedef uint32_t kvaddr_t;
typedef uint32_t paddr_t;

/*** A Linear Memory Allocator ***/

static paddr_t phys_alloc_start;

static uint32_t
round_up(uint32_t x, uint32_t y) {
    assert(y > 0);
    uint32_t z= x + (y - 1);
    return z - (z % y);
}

/* Advance the allocator to an address with the given alignment. */
static paddr_t
align_alloc(paddr_t align) {
    phys_alloc_start= round_up(phys_alloc_start, align);
    return phys_alloc_start;
}

/* Allocate an aligned block. */
static paddr_t
phys_alloc(size_t size, size_t align) {
    align_alloc(align);
    paddr_t addr= phys_alloc_start;
    phys_alloc_start+= size;
    return addr;
}

/*** Failure Handling ***/

void
fail(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    exit(EXIT_FAILURE);
}

static void
fail_errno(const char *fmt, ...) {
    char s[1024];

    va_list ap;
    va_start(ap, fmt);
    vsnprintf(s, 1024, fmt, ap);
    va_end(ap);

    perror(s);
    exit(EXIT_FAILURE);
}

static void
fail_elf(const char *s) {
    fprintf(stderr, "%s: %s\n", s, elf_errmsg(elf_errno()));
    exit(EXIT_FAILURE);
}

struct loaded_image {
    void *segment;
    paddr_t segment_base; /* Unrelocated. */
    size_t segment_size;

    size_t loaded_size;
    paddr_t loaded_paddr;
    kvaddr_t loaded_vaddr;

    kvaddr_t relocated_entry;
    const char *extrasym_name;
    void *extrasym_ptr;

    void *shdrs, *symtab, *strtab, *shstrtab;
    size_t shdrs_size, symtab_size, strtab_size, shstrtab_size;
    size_t shdrs_entsize, symtab_entsize;
};

/*** Output ELF Creation ***/

static char *strings;
static size_t strings_size= 0;

static void
init_strings(void) {
    strings_size= 1;
    strings= calloc(strings_size, 1);
    if(!strings) fail_errno("malloc");
}

static size_t
add_string(const char *s) {
    /* The new string begins just past the current end. */
    size_t start= strings_size;

    /* Extend the buffer. */
    strings_size+= strlen(s) + 1;
    strings= realloc(strings, strings_size);
    if(!strings) fail_errno("realloc");

    /* Copy the new string in. */
    strcpy(strings + start, s);

    /* Return the index of the new string. */
    return start;
}

/* Keep track of where we are in the output ELF file. */
#define ELF_HEADER_SPACE 0x4000

static size_t current_elf_offset= 0;

static size_t
get_elf_offset(void) {
    return current_elf_offset;
}

static size_t
increase_elf_offset(size_t n) {
    size_t old_offset= current_elf_offset;
    current_elf_offset+= n;
    return old_offset;
}

static size_t
align_elf_offset(size_t align) {
    current_elf_offset= round_up(current_elf_offset, align);
    return current_elf_offset;
}

static void
advance_elf_offset(size_t n) {
    assert(n + ELF_HEADER_SPACE >= current_elf_offset);
    current_elf_offset= n + ELF_HEADER_SPACE;
}

/* Keep track of the highest physical address we've allocated, so we know how
 * large the loadable segment is. */
static paddr_t greatest_paddr= 0;

/* Add an image (module or multiboot header) in its own section. */
static Elf32_Shdr *
add_blob(Elf *elf, const char *name, void *image, size_t size,
          paddr_t paddr) {
    /* Create the section. */
    Elf_Scn *scn= elf_newscn(elf);
    if(!scn) fail_elf("elf_newscn");

    /* Add the image as a new data blob. */
    Elf_Data *data= elf_newdata(scn);
    if(!data) fail_elf("elf_newdata");

    data->d_align=   1;
    data->d_buf=     image;
    data->d_off=     0;
    data->d_size=    size;
    data->d_type=    ELF_T_BYTE;
    data->d_version= EV_CURRENT;

    /* Initialise the section header. */
    Elf32_Shdr *shdr= elf32_getshdr(scn);
    if(!shdr) fail_elf("elf32_getshdr");

    if(name) shdr->sh_name= add_string(name);
    else     shdr->sh_name= 0;
    shdr->sh_type=   SHT_PROGBITS;
    shdr->sh_flags=  SHF_WRITE | SHF_ALLOC | SHF_EXECINSTR;
    /* The loader ELF contains the *physical* addresses. */
    shdr->sh_addr=   (uint32_t)paddr;
    shdr->sh_size=   size;
    shdr->sh_offset= increase_elf_offset(size);

    paddr_t last_byte= paddr + size - 1;
    if(last_byte > greatest_paddr) greatest_paddr= last_byte;

    return shdr;
}

/* Add a loaded image as a blob, without individual section headers. */
static Elf32_Shdr *
add_image(Elf *elf, const char *name, struct loaded_image *image) {
    return add_blob(elf, name, image->segment, image->loaded_size,
                    image->loaded_paddr);
}

/* Update any addresses stored in this table. */
void
update_table(uint32_t sh_type, void *section_data, size_t sh_size,
             size_t sh_entsize, kvaddr_t segment_base, kvaddr_t loaded_vaddr,
             size_t *index_map, size_t nshdr) {
    switch(sh_type) {
        case SHT_DYNSYM:
        case SHT_SYMTAB: {
            size_t nsym= sh_size / sh_entsize;
            DBG("Relocating %zu symbols.\n", nsym);

            for(size_t i= 0; i < nsym; i++) {
                Elf32_Sym *sym= section_data + i * sh_entsize;

                /* Absolute values needn't be relocated. */
                if(sym->st_shndx == SHN_ABS) continue;

                /* These shouldn't appear in executables. */
                assert(sym->st_shndx != SHN_COMMON);

                /* Update the section index. */
                assert(sym->st_shndx < nshdr);
                sym->st_shndx= index_map[sym->st_shndx];

                /* Skip the null symbol. */
                if(sym->st_shndx == SHN_UNDEF) continue;

                /* Relocate the symbol to its loaded KV address. */
                sym->st_value= (sym->st_value - segment_base) + loaded_vaddr;
            }

            break;
        }
        case SHT_REL: {
            size_t nrel= sh_size / sh_entsize;
            DBG("Rebasing %zu relocations.\n", nrel);

            for(size_t i= 0; i < nrel; i++) {
                Elf32_Rel *rel= section_data + i * sh_entsize;

                /* Update the relocation's target address. */
                rel->r_offset= (rel->r_offset - segment_base) + loaded_vaddr;
            }

            break;
        }
        case SHT_RELA:
            fail("Didn't expect RELA sections.\n");
    }
}

/* Add a loaded image by including all its loadable sections, and its symbol
 * and string tables. */
Elf32_Shdr *
add_image_with_sections(Elf *elf, struct loaded_image *image) {
    Elf32_Shdr *first_shdr= NULL;

    assert(image->shdrs);
    assert(image->shstrtab);

    size_t nshdr= image->shdrs_size / image->shdrs_entsize;
    DBG("%zu section headers to translate\n", nshdr);

    size_t *new_index= alloca(nshdr * sizeof(size_t));
    bzero(new_index, nshdr * sizeof(size_t));

    Elf_Scn **new_scn= alloca(nshdr * sizeof(Elf_Scn *));
    bzero(new_scn, nshdr * sizeof(Elf_Scn *));

    /* For every allocatable section within the loadable segment, relocate it
     * and add it to the output ELF. */
    for(size_t i= 0; i < nshdr; i++) {
        Elf32_Shdr *shdr= image->shdrs + i * image->shdrs_entsize;

        if(!(shdr->sh_flags & SHF_ALLOC)) {
            DBG("section %zu not allocatable.\n", i);
            continue;
        }

        if(shdr->sh_addr <  image->segment_base ||
           shdr->sh_addr >= image->segment_base + image->segment_size) {
            DBG("section %zu not in the loaded segment.\n", i);
            continue;
        }

        assert(shdr->sh_addr + shdr->sh_size <=
               image->segment_base + image->segment_size);

        const char *name= image->shstrtab + shdr->sh_name;
        DBG("Adding section %zu: %s\n", i, name);

        /* Create the section. */
        new_scn[i]= elf_newscn(elf);
        if(!new_scn[i]) fail_elf("elf_newscn");

        size_t ndx= elf_ndxscn(new_scn[i]);
        if(ndx == SHN_UNDEF) fail_elf("elf_ndxscn");
        new_index[i]= ndx;
        DBG("New section index is %zu\n", ndx);

        uint32_t offset_in_seg= shdr->sh_addr - image->segment_base;
        void *section_data= image->segment + offset_in_seg;

        /* The previous section's size may have not have taken us up to our
         * base address, so warp forward. */
        advance_elf_offset(offset_in_seg);

        /* Add the section data. */
        Elf_Data *data= elf_newdata(new_scn[i]);
        if(!data) fail_elf("elf_newdata");

        /* Add the correct block of the loaded segment. */
        data->d_align=   1; /* XXX */
        data->d_buf=     section_data;
        data->d_off=     0;
        data->d_size=    shdr->sh_size;
        data->d_type=    ELF_T_BYTE;
        data->d_version= EV_CURRENT;

        /* Create a new section header, with relocated addresses. */
        Elf32_Shdr *new_shdr= elf32_getshdr(new_scn[i]);
        if(!new_shdr) fail_elf("elf32_getshdr");
        if(!first_shdr) first_shdr= new_shdr;

        new_shdr->sh_name=      add_string(name);
        new_shdr->sh_type=      shdr->sh_type;
        new_shdr->sh_flags=     shdr->sh_flags;
        /* Relocate the segment address. */
        new_shdr->sh_addr=      image->loaded_vaddr + offset_in_seg;
        new_shdr->sh_offset=    increase_elf_offset(shdr->sh_size);
        new_shdr->sh_size=      shdr->sh_size;
        new_shdr->sh_link=      shdr->sh_link; /* We'll update this soon. */
        new_shdr->sh_info=      shdr->sh_info;
        new_shdr->sh_addralign= shdr->sh_addralign;
        new_shdr->sh_entsize=   shdr->sh_entsize;

        DBG("Section base %08x, size %x\n", new_shdr->sh_addr,
                new_shdr->sh_size);
        DBG("Section offset %u\n", new_shdr->sh_offset);
        DBG("Align %d %d\n", shdr->sh_addralign,
                new_shdr->sh_addr % shdr->sh_addralign);

        //assert(new_shdr->sh_offset % new_shdr->sh_addralign == 0);

        paddr_t paddr= image->loaded_paddr + offset_in_seg;
        paddr_t last_byte= paddr + shdr->sh_size - 1;
        if(last_byte > greatest_paddr) greatest_paddr= last_byte;
    }

    /* Now that all sections have been allocated new headers, walk through and
     * update any section->section links, and modify symbol and relocation
     * tables.  */
    for(size_t i= 0; i < nshdr; i++) {
        if(!new_scn[i]) continue;

        Elf32_Shdr *shdr= elf32_getshdr(new_scn[i]);
        if(!shdr) fail_elf("elf32_getshdr");

        assert(shdr->sh_link < nshdr);
        shdr->sh_link= new_index[shdr->sh_link];

        uint32_t offset_in_seg= shdr->sh_addr - image->loaded_vaddr;
        void *section_data= image->segment + offset_in_seg;

        /* If this is a symbol or relocation table, any addresses in it must
         * be relocated. */
        update_table(shdr->sh_type, section_data, shdr->sh_size,
                     shdr->sh_entsize, image->segment_base,
                     image->loaded_vaddr, new_index, nshdr);
    }

    /* Update the pointers in the symbol table now, while we've got the
     * information to do it. */
    update_table(SHT_SYMTAB, image->symtab, image->symtab_size,
                 image->symtab_entsize, image->segment_base,
                 image->loaded_vaddr, new_index, nshdr);

    return first_shdr;
}

/* Add the non-loadable tables from an image.  This is separated from
 * load_image_with_sections(), as they need to come last, such that we have a
 * contiguous loadable segment. */
static void
add_tables(Elf *elf, struct loaded_image *image) {
    /* Add the string table for the loaded image. */
    size_t strtabndx;
    {
        assert(image->strtab);

        /* Create the section. */
        Elf_Scn *scn= elf_newscn(elf);
        if(!scn) fail_elf("elf_newscn");

        strtabndx= elf_ndxscn(scn);
        if(strtabndx == SHN_UNDEF) fail_elf("elf_ndxscn");

        Elf_Data *data= elf_newdata(scn);
        if(!data) fail_elf("elf_newdata");

        data->d_align=   1;
        data->d_buf=     image->strtab;
        data->d_off=     0;
        data->d_size=    image->strtab_size;
        data->d_type=    ELF_T_BYTE;
        data->d_version= EV_CURRENT;

        /* Initialise the section header. */
        Elf32_Shdr *shdr= elf32_getshdr(scn);
        if(!shdr) fail_elf("elf32_getshdr");

        shdr->sh_name=   add_string(".strtab");
        shdr->sh_type=   SHT_STRTAB;
        shdr->sh_offset= increase_elf_offset(image->strtab_size);
        shdr->sh_size=   image->strtab_size;
        shdr->sh_flags=  0;
        shdr->sh_addr=   0;
    }

    /* Add the symbol table. */
    {
        assert(image->symtab);

        /* Create the section. */
        Elf_Scn *scn= elf_newscn(elf);
        if(!scn) fail_elf("elf_newscn");

        Elf_Data *data= elf_newdata(scn);
        if(!data) fail_elf("elf_newdata");

        data->d_align=   1;
        data->d_buf=     image->symtab;
        data->d_off=     0;
        data->d_size=    image->symtab_size;
        data->d_type=    ELF_T_BYTE;
        data->d_version= EV_CURRENT;

        /* Initialise the section header. */
        Elf32_Shdr *shdr= elf32_getshdr(scn);
        if(!shdr) fail_elf("elf32_getshdr");

        /* Elf32_Rel must be aligned to 4 bytes. */
        align_elf_offset(4);

        shdr->sh_name=    add_string(".symtab");
        shdr->sh_type=    SHT_SYMTAB;
        shdr->sh_flags=   0;
        shdr->sh_addr=    0;
        shdr->sh_offset=  increase_elf_offset(image->symtab_size);
        shdr->sh_size=    image->symtab_size;
        shdr->sh_link=    strtabndx; /* Link the string table. */
        shdr->sh_entsize= image->symtab_entsize;
    }
}

/* Add the section name string table. */
static void
add_strings(Elf *elf) {
    Elf_Scn *scn= elf_newscn(elf);
    if(!scn) fail_elf("elf_newscn");

    size_t nameidx= add_string(".shstrtab");

    Elf_Data *data= elf_newdata(scn);
    if(!data) fail_elf("elf_newdata");

    data->d_align=   1;
    data->d_buf=     strings;
    data->d_off=     0;
    data->d_size=    strings_size;
    data->d_type=    ELF_T_BYTE;
    data->d_version= EV_CURRENT;

    /* Initialise the string table section header. */
    Elf32_Shdr *shdr= elf32_getshdr(scn);
    if(!shdr) fail_elf("elf32_getshdr");

    shdr->sh_name=      nameidx;
    shdr->sh_type=      SHT_STRTAB;
    shdr->sh_flags=     SHF_STRINGS;
    shdr->sh_offset=    increase_elf_offset(strings_size);
    shdr->sh_size=      strings_size;
    shdr->sh_addralign= 1;

    elf_setshstrndx(elf, elf_ndxscn(scn));
};

static void
join_paths(char *dst, const char *src1, const char *src2) {
    strcpy(dst, src1);
    dst[strlen(src1)]= '/';
    strcpy(dst + strlen(src1) + 1, src2);
}

struct
loaded_module {
    void *data;
    paddr_t paddr;
    size_t len;
    const char *shortname;
};

/* Load an ELF file as a raw data blob. */
void
raw_load(const char *path, struct loaded_module *m) {
    struct stat mstat;

    if(stat(path, &mstat)) fail_errno("stat: %s", path);

    size_t data_len= mstat.st_size;
    m->len= round_up(data_len, BASE_PAGE_SIZE);
    m->data= calloc(m->len, 1);
    if(!m->data) fail_errno("calloc");
    m->paddr= phys_alloc(m->len, BASE_PAGE_SIZE);

    printf("Allocated 0x%zxB at PA %08x for %s\n", m->len, m->paddr, path);

    FILE *f= fopen(path, "r");
    size_t read_len= fread(m->data, 1, data_len, f);
    if(read_len != data_len) fail_errno("fread");
    if(fclose(f)) fail_errno("fclose");
}

/*** Multiboot ***/

/* Create the multiboot header, using only *physical* addresses. */
void *
create_multiboot_info(struct menu_lst *menu, struct loaded_module *modules,
                      size_t *mb_size, paddr_t *mb_base) {
    size_t size;
    
    /* Calculate the size of the multiboot info header, not including the
     * module ELF images themselves, but including the MMAP, and the
     * command-line strings. */
    size= sizeof(struct multiboot_info);

    /* Include NULL terminator, and separating space. */
    size+= strlen(menu->kernel.path) + strlen(menu->kernel.args) + 2;

    /* Module headers and command-line strings. */
    size+= menu->nmodules * sizeof(struct multiboot_modinfo);
    for(size_t i= 0; i < menu->nmodules; i++) {
        size+= strlen(menu->modules[i].path) +
               strlen(menu->modules[i].args) + 2;
    }

    /* Memory map. */
    size+= menu->mmap_len * sizeof(struct multiboot_mmap);

    /* Allocate target addresses. */
    paddr_t base= phys_alloc(size, BASE_PAGE_SIZE);
    printf("Allocated %luB at PA %08x for multiboot\n", size, base);
    *mb_size= size;
    *mb_base= base;

    /* Allocate our host buffer. */
    void *mb= calloc(size, 1);
    if(!mb) fail_errno("calloc");

    /* Lay the multiboot info out as follows:
            ---------------------------
            struct multiboot_info;
            ---------------------------
            struct multiboot_mmap[];
            ---------------------------
            struct multiboot_modinfo[];
            ---------------------------
            char strings[];
            ---------------------------
     */
    struct multiboot_info *mbi= mb;

    paddr_t mmap_base= base + sizeof(struct multiboot_info);
    struct multiboot_mmap *mmap= mb + sizeof(struct multiboot_info);

    paddr_t modinfo_base= mmap_base +
                   menu->mmap_len * sizeof(struct multiboot_mmap);
    struct multiboot_modinfo *modinfo= (void *)mmap +
                   menu->mmap_len * sizeof(struct multiboot_mmap);

    paddr_t strings_base= modinfo_base +
                   menu->nmodules * sizeof(struct multiboot_modinfo);
    char *strings= (void *)modinfo +
                   menu->nmodules * sizeof(struct multiboot_modinfo);
    size_t strings_idx= 0;

    /* Fill in the info header */
    mbi->flags= MULTIBOOT_INFO_FLAG_HAS_CMDLINE
              | MULTIBOOT_INFO_FLAG_HAS_MODS
              | MULTIBOOT_INFO_FLAG_HAS_MMAP;

    /* Concatenate the path and arguments, separated by a space. */
    mbi->cmdline= strings_base + strings_idx;
    strcpy(strings + strings_idx, menu->kernel.path);
    strings_idx+= strlen(menu->kernel.path);
    strings[strings_idx]= ' ';
    strings_idx+= 1;
    strcpy(strings + strings_idx, menu->kernel.args);
    strings_idx+= strlen(menu->kernel.args) + 1;

    mbi->mods_count= menu->nmodules;
    mbi->mods_addr= modinfo_base;

    mbi->mmap_length= menu->mmap_len;
    mbi->mmap_addr= mmap_base;

    /* Add the MMAP entries. */
    for(size_t i= 0; i < menu->mmap_len; i++) {
        mmap[i].size=      sizeof(struct multiboot_mmap);
        mmap[i].base_addr= menu->mmap[i].base;
        mmap[i].length=    menu->mmap[i].length;
        mmap[i].type=      menu->mmap[i].type;
    }

    /* Add the modinfo headers. */
    for(size_t i= 0; i < menu->nmodules; i++) {
        modinfo[i].mod_start= modules[i].paddr;
        modinfo[i].mod_end=
            modules[i].paddr + modules[i].len;

        modinfo[i].string= strings_base + strings_idx;
        strcpy(strings + strings_idx, menu->modules[i].path);
        strings_idx+= strlen(menu->modules[i].path);
        strings[strings_idx]= ' ';
        strings_idx+= 1;
        strcpy(strings + strings_idx, menu->modules[i].args);
        strings_idx+= strlen(menu->modules[i].args) + 1;
    }

    return mb;
}

/*** Main ***/

void
usage(const char *name) {
    fail("Usage: %s <menu.lst> <boot driver> <output filename>\n"
         "          <build directory> <physical base address>\n",
         name);
}

/* Find the first (lowest base address) RAM region. */
static struct menu_mmap_entry *
first_ram_region(struct menu_lst *menu) {
    struct menu_mmap_entry *first= NULL;
    uint64_t lowest_base= UINT64_MAX;

    for(uint32_t i= 0; i < menu->mmap_len; i++) {
        struct menu_mmap_entry *e= &menu->mmap[i];

        if(e->type == MULTIBOOT_MEM_TYPE_RAM && e->base < lowest_base) {
            lowest_base= e->base;
            first= e;
        }
    }

    return first;
}

// this is mips boot_image
int
main(int argc, char **argv) {
    char pathbuf[PATH_MAX+1];

    if(argc != 6) usage(argv[0]);

    const char *menu_lst=   argv[1],
               *infile =    argv[2],
               *outfile=    argv[3],
               *buildroot=  argv[4];

    errno= 0;
    paddr_t phys_base= strtoul(argv[5], NULL, 0);
    if(errno) fail_errno("strtoul");

    printf("MIPS Static Bootloader\n");

    /* Read the menu.lst file. */
    printf("Reading boot configuration from %s\n", menu_lst);
    struct menu_lst *menu= read_menu_lst(menu_lst);

    /* Check that the requested base address is inside the first RAM region. */
    struct menu_mmap_entry *ram_region= first_ram_region(menu);
    if(!ram_region) fail("No RAM regions defined.\n");
    if(ram_region->base > (uint64_t)UINT32_MAX)
        fail("This seems to be a 64-bit memory map.\n");
    if(phys_base < ram_region->base |
       phys_base >= ram_region->base + ram_region->length) {
        fail("Requested base address %08x is outside the first RAM region.\n",
             phys_base);
    }
    paddr_t ram_start= (paddr_t)ram_region->base;
    uint32_t kernel_offset= KERNEL_WINDOW - ram_start;

    /* Begin allocation at the requested start address. */
    phys_alloc_start= phys_base;
    printf("Beginning allocation at PA %08x (VA %08x)\n",
           phys_base, phys_base + kernel_offset);

    if(elf_version(EV_CURRENT) == EV_NONE)
        fail("ELF library version out of date.\n");

    /*** Load the boot driver. ***/

    /* Open the boot driver and cpu driver ELF. */
    printf("Loading %s\n", infile);
    int bd_cpu_fd= open(infile, O_RDONLY);
    if(bd_cpu_fd < 0) fail_errno("open");

    // XXX: currently we get the basic ELF, add something!

    /* Close the ELF. */
    if(close(bd_cpu_fd) < 0) fail_errno("close");
    /*** Load the modules. ***/

    struct loaded_module *modules=
        calloc(menu->nmodules, sizeof(struct loaded_module));
    if(!modules) fail_errno("calloc");

    for(size_t i= 0; i < menu->nmodules; i++) {
        join_paths(pathbuf, buildroot, menu->modules[i].path);
        raw_load(pathbuf, &modules[i]);

        /* Use the filename as a short identifier. */
        const char *lastslash= strrchr(menu->modules[i].path, '/');
        if(lastslash) modules[i].shortname= lastslash + 1;
        else          modules[i].shortname= "";
    }

    /*** Create the multiboot info header. ***/
    size_t mb_size;
    paddr_t mb_base;
    void *mb_image= create_multiboot_info(menu, modules, &mb_size, &mb_base);

    /* Set the 'static_multiboot' pointer to the kernel virtual address of the
     * multiboot image.  Pass the CPU driver entry point. */

    // XXX: do something here

    /*** Write the output file. ***/

    init_strings();

    /* Open the output image file. */
    printf("Writing to %s\n", outfile);
    int out_fd= open(outfile, O_WRONLY | O_CREAT | O_TRUNC,
                     S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP |
                     S_IROTH | S_IWOTH);
    if(out_fd < 0) fail_errno("open");

    /* Create the output ELF file. */
    Elf *out_elf= elf_begin(out_fd, ELF_C_WRITE, NULL);
    if(!out_elf) fail_elf("elf_begin");

    /* We need to lay our sections out explicitly. */
    if(!elf_flagelf(out_elf, ELF_C_SET, ELF_F_LAYOUT)) fail_elf("elf_flagelf");

    /* Create the ELF header. */
    Elf32_Ehdr *out_ehdr= elf32_newehdr(out_elf);
    if(!out_ehdr) fail_elf("elf32_newehdr");

    /* Little-endian MIPS executable. */
    out_ehdr->e_ident[EI_DATA]= ELFDATA2LSB;
    out_ehdr->e_type=           ET_EXEC;
    out_ehdr->e_machine=        EM_MIPS;
    //out_ehdr->e_entry=          bd_image.relocated_entry;
    /* Program headers after the executable header. */
    increase_elf_offset(sizeof(Elf32_Ehdr));
    out_ehdr->e_phoff=          get_elf_offset();

    /* Create a single program header (segment) to cover everything that we
     * need to load. */
    Elf32_Phdr *out_phdr= elf32_newphdr(out_elf, 1);
    if(!out_phdr) fail_elf("elf32_newphdr");
    increase_elf_offset(sizeof(Elf32_Phdr));

    /* Advance to an aligned address to make section alignment easier. */
    advance_elf_offset(0);

    /* The boot driver, CPU driver and multiboot image all get their own
     * sections. */
    size_t loadable_segment_offset= get_elf_offset();
    Elf32_Shdr *fst_shdr= add_image_with_sections(out_elf, &bd_image);
    advance_elf_offset(cpu_image.loaded_paddr - phys_base);
    Elf32_Shdr *cpu_shdr= add_image(out_elf, ".cpudriver", &cpu_image);
    for(size_t i= 0; i < menu->nmodules; i++) {
        char name[32];
        snprintf(name, 32, ".elf.%s", modules[i].shortname);
        advance_elf_offset(modules[i].paddr - phys_base);
        add_blob(out_elf, name, modules[i].data, modules[i].len,
                 modules[i].paddr);
    }
    advance_elf_offset(mb_base - phys_base);
    add_blob(out_elf, ".multiboot", mb_image, mb_size, mb_base);
    size_t end_of_segment= get_elf_offset();

    /* Add the boot driver's string and symbol tables. */
    add_tables(out_elf, &bd_image);

    /* Add the string table.  This must be the last section added, as it
     * contains the names of all other sections. */
    add_strings(out_elf);

    /* Elf32_Shdr must be aligned to 4 bytes. */
    align_elf_offset(4);

    /* Place the section headers. */
    out_ehdr->e_shoff= get_elf_offset();

    size_t total_size= end_of_segment - loadable_segment_offset;
    if(total_size > ram_region->length)
        fail("Overflowed the first RAM region.\n");

    out_phdr->p_type=   PT_LOAD;
    out_phdr->p_offset= loadable_segment_offset;
    out_phdr->p_vaddr=  phys_base; /* Load at physical address. */
    out_phdr->p_paddr=  phys_base; /* Actually ignored. */
    /* This is dodgy, but GEM5 refuses to load an image that doesn't have a
     * BSS, and hence a larger memsz then filesz.  Purely a hack, and luckily
     * doesn't seem to affect non-dodgy simulators. */
    out_phdr->p_memsz=  round_up(total_size + 1, BASE_PAGE_SIZE);
    out_phdr->p_filesz= total_size;
    out_phdr->p_align=  1;
    out_phdr->p_flags=  PF_X | PF_W | PF_R;

    elf_flagphdr(out_elf, ELF_C_SET, ELF_F_DIRTY);

    /* Write the file. */
    if(elf_update(out_elf, ELF_C_WRITE) < 0) fail_elf("elf_update");

    if(elf_end(out_elf) < 0) fail_elf("elf_update");
    if(close(out_fd) < 0) fail_errno("close");

    return EXIT_SUCCESS;
}
