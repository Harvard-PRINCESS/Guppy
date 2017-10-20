#include <lser.h>
#include <lamebus.h>
#include <console.h>
#include <errno.h>
#include <barrelfish/types.h>
#include <offsets.h>

/* Lowest revision we support */
#define LOW_VERSION   1
static int nextunit_lser;
static int nextunit_con;
static void autoconf_con(struct con_softc *, int);
static void autoconf_lser(struct lser_softc *, int);
static struct lamebus_softc *lamebus;

struct lser_softc * attach_lser_to_lamebus(int lserno, struct lamebus_softc *sc)
{
	struct lser_softc *ls;
	int slot = lamebus_probe(sc, LB_VENDOR_CS161, LBCS161_SERIAL,
				 LOW_VERSION, NULL);
	if (slot < 0) {
		return NULL;
	}

	ls = malloc(sizeof(struct lser_softc));
	if (ls==NULL) {
		return NULL;
	}

	ls->ls_busdata = sc;
	ls->ls_buspos = slot;

	lamebus_mark(sc, slot);
	lamebus_attach_interrupt(sc, slot, ls, lser_irq);

	return ls;
}

struct con_softc * attach_con_to_lser(int consno, struct lser_softc *ls)
{
	struct con_softc *cs = malloc(sizeof(struct con_softc));
	if (cs==NULL) {
		return NULL;
	}

	cs->cs_devdata = ls;
	cs->cs_send = lser_write;
	cs->cs_sendpolled = lser_writepolled;

	ls->ls_devdata = cs;
	ls->ls_start = con_start;
	ls->ls_input = con_input;

	return cs;
}


static int tryattach_con_to_lser(int devunit, struct lser_softc *bus, int busunit)
{
	struct con_softc *dev;
	int result;

	dev = attach_con_to_lser(devunit, bus);
	if (dev==NULL) {
		return -1;
	}
	result = config_con(dev, devunit);
	if (result != 0) {
		/* should really clean up dev */
		return result;
	}
	nextunit_con = devunit+1;
	autoconf_con(dev, devunit);
	return 0;
}


static int tryattach_lser_to_lamebus(int devunit, struct lamebus_softc *bus, int busunit)
{
	struct lser_softc *dev;
	int result;

	dev = attach_lser_to_lamebus(devunit, bus);
	if (dev==NULL) {
		return -1;
	}
	//kprintf("lser%d at lamebus%d", devunit, busunit);
	result = config_lser(dev, devunit);
	if (result != 0) {
		//kprintf(": %s\n", strerror(result));
		/* should really clean up dev */
		return result;
	}
	//kprintf("\n");
	nextunit_lser = devunit+1;
	autoconf_lser(dev, devunit);
	return 0;
}


static void autoconf_con(struct con_softc *bus, int busunit)
{
	(void)bus; (void)busunit;
}

static void autoconf_lser(struct lser_softc *bus, int busunit)
{
	(void)bus; (void)busunit;
	{
		if (nextunit_con <= 0) {
			tryattach_con_to_lser(0, bus, busunit);
		}
	}
}

void autoconf_lamebus(struct lamebus_softc *bus, int busunit)
{
	(void)bus; (void)busunit;
	{
		int result, devunit=nextunit_lser;
		do {
			result = tryattach_lser_to_lamebus(devunit, bus, busunit);
			devunit++;
		} while (result==0);
	}
}


/*
 * LAMEbus Initialization
 */
uintptr_t serial_early_init(unsigned port)
{

	/* Initialize the system LAMEbus data */
	lamebus = lamebus_init();

	/*
	 * Now probe all the devices attached to the bus.
	 * (This amounts to all devices.)
	 */
	autoconf_lamebus(lamebus, 0);

    return 0;
}
