
#ifndef __CP0_H__
#define __CP0_H__

#include <specialreg.h>

// set status register
static inline void cp0_write_status(uint32_t status) {
    __asm volatile("mtc0 %[status], c0_status" : : [status] "g" (status));
}

// set context register
static inline void cp0_write_context(uint32_t ctx) {
    __asm volatile("mtc0 %[ctx], c0_context" : : [ctx] "g" (ctx));
}

// XXX for both write_status and write_context, unsure if mtc0 takes
// a memory location (e.g. 'g' operand constraint): if it breaks, switch to 'r'

#endif
