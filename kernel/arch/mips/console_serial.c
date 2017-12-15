#include <dev/mips/lamebus_dev.h>
#include <platform.h>
#include <serial.h>

#define MAX_PORTS 1
static lamebus_t console[MAX_PORTS];


errval_t serial_early_init(unsigned n)
{
    lamebus_initialize(&console[n], (mackerel_addr_t)console_base_array[n]);

    return SYS_ERR_OK;
}
/*
 * \brief Put a character to the port
 */
void serial_putchar(unsigned port, char c)
{
	lamebus_t *l = &console[port];
	lamebus_serial_console_character_buffer_wrf(l, c);
}

/*
 * \brief Read a character from a port
 */
char serial_getchar(unsigned port)
{
	lamebus_t *l = &console[port];
    return (char)lamebus_serial_console_character_buffer_rdf(l);
}