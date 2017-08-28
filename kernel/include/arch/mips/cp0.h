
#ifndef __CP0_H__
#define __CP0_H__

#include <stdint.h>
#include <specialreg.h>

// XXX I don't think __asm volatile permits preprocessor macro expansion...

// set status register
static inline void cp0_write_status(uint32_t status) {
    __asm volatile("mtc0 %[status], $12" : : [status] "r" (status));
    // $12 is c0_status
}

// set context register
static inline void cp0_write_context(uint32_t ctx) {
    __asm volatile("mtc0 %[ctx], $4" : : [ctx] "r" (ctx));
    // $4 is c0_context
}

// for both write_status and write_context, unsure if mtc0 takes
// a memory location (e.g. 'g' operand constraint): if it breaks, switch to 'r'

#endif
