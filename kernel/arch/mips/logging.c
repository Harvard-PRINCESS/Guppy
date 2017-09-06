// XXX stub file to divert __assert_func error
// just jumps to the panic in start.S

void panic() {
    while (1);
}

void __assert_func(const char *file, int line, const char *func, const char *exp) {
    panic();
}
