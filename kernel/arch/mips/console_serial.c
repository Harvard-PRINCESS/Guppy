#include <dev/mips/serial_console_dev.h>
#include <platform.h>
#include <serial.h>

#define MAX_PORTS 1
#define IRQ_ENABLE  1
#define IRQ_ACTIVE  2
#define IRQ_FORCE   4
static serial_console_t console[MAX_PORTS];


errval_t serial_early_init(unsigned n)
{
	serial_console_t *l = &console[n];
    serial_console_initialize(&console[n], (mackerel_addr_t)console_base_array[n]);
    // set the interrupt to 0
	serial_console_write_irq_reg_rawwr(l, IRQ_ACTIVE);
	serial_console_read_irq_reg_rawwr(l, 0);

    return SYS_ERR_OK;
}
void serial_wait(serial_console_t *l)
{
	uint32_t val;
	// do something like: while(pl011_uart_FR_txff_rdf(u) == 1) ;
	// the logic is: lser_poll_until_write and lser_writepolled
	do{
		val = serial_console_write_irq_reg_rawrd(l);
	} while ((val & IRQ_ACTIVE) == 0);
}
/*
 * \brief Put a character to the port
 */
void serial_putchar(unsigned port, char c)
{
	serial_console_t *l = &console[port];

	// do something like: while(pl011_uart_FR_txff_rdf(u) == 1) ;
	// the logic is: lser_poll_until_write and lser_writepolled
	serial_wait(l);
	serial_console_write_irq_reg_rawwr(l, 0);
	serial_console_character_buffer_rawwr(l, c);
}

/*
 * \brief Read a character from a port
 */
char serial_getchar(unsigned port)
{
	serial_console_t *l = &console[port];
    return (char)serial_console_character_buffer_data_rdf(l);
}