
#ifndef LAMEBUS_MAP_H
#define LAMEBUS_MAP_H

#define MIPS_BASE	0x80000000
#define LAMEBASE	(MIPS_BASE + 0x1fe00000)
#define SLOT0      LAMEBASE
#define SLOT0_SIZE     0x10000
#define SLOT1      (LAMEBASE + 0x10000)
#define SLOT1_SIZE     0x10000
#define SLOT2      (LAMEBASE + 0x20000)
#define SLOT2_SIZE     0x10000
#define SLOT3      (LAMEBASE + 0x30000)
#define SLOT3_SIZE     0x10000


#endif // LAMEBUS_MAP_H