#include <sys/stat.h>
#include <sys/types.h>
#include <endian.h>

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

    // MBI endianness hack
    // also mmap, modinfo entries
    // check your shit when you execute the modules themselves
    // if the endianness is wrong, deal with it
    // XXX we hard-wired it to be flipped around for MIPS
    mbi->flags = htobe32(mbi->flags);
    mbi->cmdline = htobe32(mbi->cmdline);
    mbi->mods_count = htobe32(mbi->mods_count);
    mbi->mods_addr = htobe32(mbi->mods_addr);
    mbi->mmap_length = htobe32(mbi->mmap_length);
    mbi->mmap_addr = htobe32(mbi->mmap_addr);

    for (size_t i = 0; i < menu->mmap_len; i++) {
        mmap[i].size = htobe32(mmap[i].size);
        mmap[i].base_addr = htobe64(mmap[i].base_addr);
        mmap[i].length = htobe64(mmap[i].length);
        mmap[i].type = htobe32(mmap[i].type);
    }

    for(size_t i= 0; i < menu->nmodules; i++) {
        modinfo[i].mod_start = htobe32(modinfo[i].mod_start);
        modinfo[i].mod_end = htobe32(modinfo[i].mod_end);
        modinfo[i].string = htobe32(modinfo[i].string);
    }

    return mb;
}

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

int main(int argc, char **argv){
    char pathbuf[PATH_MAX+1];

    const char *menu_lst=   argv[1],
               *buildroot=  argv[2],
               *outfile=    argv[3];
    errno= 0;
    paddr_t phys_base= strtoul(argv[4], NULL, 0);
    if(errno) fail_errno("strtoul");

    /* Read the menu.lst file. */
    printf("Reading boot configuration from %s\n", menu_lst);
    struct menu_lst *menu= read_menu_lst(menu_lst);

    /* Begin allocation at the requested start address. */
    phys_alloc_start= phys_base;

    if(elf_version(EV_CURRENT) == EV_NONE)
        fail("ELF library version out of date.\n");

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
    // XXX: we need to do something here?

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

    /* Big-endian MIPS executable. */
    out_ehdr->e_ident[EI_DATA]= ELFDATA2MSB;
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

    size_t loadable_segment_offset= get_elf_offset();
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

    /* Add the string table.  This must be the last section added, as it
     * contains the names of all other sections. */
    add_strings(out_elf);

    /* Elf32_Shdr must be aligned to 4 bytes. */
    align_elf_offset(4);

    /* Place the section headers. */
    out_ehdr->e_shoff= get_elf_offset();

    /*get total size*/
    size_t total_size= end_of_segment - loadable_segment_offset;

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