/*
 * Copyright (c) 2007, 2008, 2009, 2010, 2011, 2012, ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Haldeneggsteig 4, CH-8092 Zurich. Attn: Systems Group.
 */

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <barrelfish/barrelfish.h>
#include <barrelfish/waitset.h>
#include <barrelfish/deferred.h>
#include <devif/queue_interface.h>
#include <devif/backends/net/sfn5122f_devif.h>


//#define TEST_FORWARD
//#define SFN_TEST_DIRECT
#define NUM_ENQ 2
#define NUM_RX_BUF 1024
#define NUM_ROUNDS 32
#define MEMORY_SIZE BASE_PAGE_SIZE*512

static struct capref memory_rx;
static struct capref memory_tx;
static regionid_t regid_rx;
static regionid_t regid_tx;
static struct frame_identity id;
static lpaddr_t phys_rx;
static lpaddr_t phys_tx;

static void* va_rx;
static void* va_tx;

struct direct_state {
    struct list_ele* first;
    struct list_ele* last;
};

struct list_ele{
    regionid_t rid;
    bufferid_t bid;
    lpaddr_t addr;
    size_t len;
    uint64_t flags;
   
    struct list_ele* next;
};

static uint8_t udp_header[8] = {
    0x07, 0xD0, 0x07, 0xD0,
    0x00, 0x80, 0x00, 0x00,
};

static void print_buffer(size_t len, bufferid_t bid)
{
    uint8_t* buf = (uint8_t*) va_rx+bid;
    printf("Packet in region %p at address %p len %zu \n", 
            va_rx, buf, len);
/*
    for (int i = 0; i < len; i++) {
        if (((i % 10) == 0) && i > 0) {
            printf("\n");
        }
        printf("%2X ", buf[i]);   
    }
    printf("\n");
*/
}


static void test_sfn5122f_device_direct(void) 
{

    errval_t err;
    struct devq* q;   
    struct sfn5122f_queue* queue;

    printf("SFN5122F direct device test started \n");
    err = sfn5122f_queue_create(&queue, true, false);
    if (err_is_fail(err)){
        USER_PANIC("Allocating devq failed \n");
    }    
    
    q = (struct devq*) queue;    

    err = devq_register(q, memory_rx, &regid_rx);
    if (err_is_fail(err)){
        USER_PANIC("Registering memory to devq failed \n");
    }
  

    err = devq_register(q, memory_tx, &regid_tx);
    if (err_is_fail(err)){
        USER_PANIC("Registering memory to devq failed \n");
    }
  
    regionid_t rid;
    bufferid_t ids[NUM_RX_BUF];
    lpaddr_t addr;
    size_t len;
    uint64_t flags;

    // Enqueue RX buffers to receive into
    for (int i = 0; i < NUM_ROUNDS; i++){
        addr = phys_rx+(i*2048);
        err = devq_enqueue(q, regid_rx, addr, 2048, 
                           DEVQ_BUF_FLAG_RX, &ids[i]);
        if (err_is_fail(err)){
            USER_PANIC("Devq enqueue failed: %s\n", err_getstring(err));
        }    

        // not necessary!
        err = devq_notify(q);
        if (err_is_fail(err)){
            USER_PANIC("Devq notify failed: %s\n", err_getstring(err));
        }    
    }

    // 32 Receives
    for (int i = 0; i < NUM_ROUNDS; i++) {
        err = devq_dequeue(q, &rid, &addr, &len, &ids[i], &flags);
        if (err_is_fail(err)){
            USER_PANIC("Devq dequeue failed \n");
        } 
        
        if (flags == DEVQ_BUF_FLAG_RX) {
            print_buffer(len, ids[i]);   
        }  
    }

    // Send something
    char* write = NULL;
    for (int i = 0; i < NUM_ROUNDS; i++) {
        addr = phys_tx+(i*2048);
        write = va_tx + i*2048;
        for (int j = 0; j < 8; j++) {
            write[j] = udp_header[j];
        }
        for (int j = 8; j < 128; j++) {
            write[j] = 'a';
        }

        err = devq_enqueue(q, regid_tx, addr, 2048, 
                           DEVQ_BUF_FLAG_TX | DEVQ_BUF_FLAG_TX_LAST, &ids[i]);
        if (err_is_fail(err)){
            USER_PANIC("Devq enqueue failed \n");
        }    

        // Not necessary
        err = devq_notify(q);
        if (err_is_fail(err)){
            USER_PANIC("Devq notify failed \n");
        }    
    }

    uint16_t tx_bufs = 0;
    while (tx_bufs < NUM_ROUNDS) {
        err = devq_dequeue(q, &rid, &addr, &len, &ids[tx_bufs], &flags);
        if (err_is_fail(err)){
            USER_PANIC("Devq dequeue failed \n");
        }    

        if (flags & DEVQ_BUF_FLAG_TX ) {
            tx_bufs++;
        }
    }

    err = devq_control(q, 1, 1);
    if (err_is_fail(err)){
        printf("%s \n", err_getstring(err));
        USER_PANIC("Devq control failed \n");
    }

    err = devq_deregister(q, regid_rx, &memory_rx);
    if (err_is_fail(err)){
        printf("%s \n", err_getstring(err));
        USER_PANIC("Devq deregister rx failed \n");
    }

    err = devq_deregister(q, regid_tx, &memory_tx);
    if (err_is_fail(err)){
        printf("%s \n", err_getstring(err));
        USER_PANIC("Devq deregister tx failed \n");
    }

    err = sfn5122f_queue_destroy((struct sfn5122f_queue*) q);

    printf("SFN5122F direct device test ended\n");
}

int main(int argc, char *argv[])
{
    //barrelfish_usleep(1000*1000*5);
    errval_t err;
    // Allocate memory
    err = frame_alloc(&memory_rx, MEMORY_SIZE, NULL);
    if (err_is_fail(err)){
        USER_PANIC("Allocating cap failed \n");
    }    

    err = frame_alloc(&memory_tx, MEMORY_SIZE, NULL);
    if (err_is_fail(err)){
        USER_PANIC("Allocating cap failed \n");
    }    
    
    // RX frame
    err = invoke_frame_identify(memory_rx, &id);
    if (err_is_fail(err)) {
        USER_PANIC("Frame identify failed \n");
    }

    err = vspace_map_one_frame_attr(&va_rx, MEMORY_SIZE, memory_rx,
                                    VREGION_FLAGS_READ, NULL, NULL); 
    if (err_is_fail(err)) {
        USER_PANIC("Frame mapping failed \n");
    }

    phys_rx = id.base;

    // TX Frame
    err = invoke_frame_identify(memory_tx, &id);
    if (err_is_fail(err)) {
        USER_PANIC("Frame identify failed \n");
    }
   
    err = vspace_map_one_frame_attr(&va_tx, MEMORY_SIZE, memory_tx,
                                    VREGION_FLAGS_WRITE, NULL, NULL); 
    if (err_is_fail(err)) {
        USER_PANIC("Frame mapping failed \n");
    }

    phys_tx = id.base;
    test_sfn5122f_device_direct();
    barrelfish_usleep(1000*1000*5);
}

