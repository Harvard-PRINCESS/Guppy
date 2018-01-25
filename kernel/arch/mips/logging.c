// XXX stub file to divert __assert_func error
// just jumps to the panic in start.S

#include <stdarg.h>
#include <stdio.h>
#include <string.h>

void panic(const char *msg, ...) {
    va_list ap;
    static char buf[256];

    va_start(ap, msg);
    vsnprintf(buf, sizeof(buf), msg, ap);
    va_end(ap);

    // printf("kernel 0 PANIC! %.*s\n", (int)sizeof(buf), buf);
    printf("p%s\n", buf);

    while(1){};
}

void __assert_func(const char *file, int line, const char *func, const char *exp) {
    panic("kernel assertion \"%s\" failed at %s:%d", exp, file, line);
}
