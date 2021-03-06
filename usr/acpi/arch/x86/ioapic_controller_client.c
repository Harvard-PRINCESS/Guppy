/**
 * \file
 * \brief Interrupt Service Controller client. Registers itself as a controller for
 * pci link devices on the int_route server.
 */

/*
 * Copyright (c) 2007, 2008, 2009, 2011, ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Haldeneggsteig 4, CH-8092 Zurich. Attn: Systems Group.
 */

#include "ioapic_controller_client.h"

#include <stdio.h>
#include <barrelfish/barrelfish.h>
#include <barrelfish/cpu_arch.h>
#include <barrelfish/nameservice_client.h>
#include <acpi.h>
#include <mm/mm.h>

#include <skb/skb.h>
#include <octopus/getset.h>
#include <trace/trace.h>

#include "acpi_debug.h"
#include "acpi_shared.h"

#include "ioapic.h"

#include <if/int_route_controller_defs.h>

// Set this switch to forward all IRQs to CPU 0
//#define IOAPIC_DEBUG_FORWARD_ALL 


static void add_mapping(struct int_route_controller_binding *b,
        const char *label,
        const char *class,
        int_route_controller_int_message_t from,
        int_route_controller_int_message_t to) {


    errval_t err = SYS_ERR_OK;

    ACPI_DEBUG("ioapic add_mapping: label:%s, class:%s (port=%"PRIu64") to"
            "(%"PRIu64", %"PRIu64")\n", label, class, from.port, to.port, to.msg);

#ifdef IOAPIC_DEBUG_FORWARD_ALL
    debug_printf("Ignoring add_mapping....\n");
    return;
#endif

    struct ioapic* ioapic = find_ioapic_for_label(label);
    if(ioapic == NULL){
        debug_printf("No ioapic found for label: %s\n", label);
        goto err_out;
    }

    // to.port is a barrelfish cpu id. Need  to translate this to apic id
    err = skb_execute_query("corename(%"PRIu64",_,apic(A)),writeln(A).", to.port);
    if(err_is_fail(err)){
        DEBUG_SKB_ERR(err, "ACPI id lookup failed");
        goto err_out;
    }

    int to_apicid = 0;
    err = skb_read_output("%d", &to_apicid);
    if(err_is_fail(err)){
        DEBUG_SKB_ERR(err, "ACPI id parse failed");
        goto err_out;
    }

    int inti = from.port;
    // route
    ACPI_DEBUG("ioapic_route_inti(irqbase=%d, inti=%d, dest_vec=%"PRIu64","
            " dest_apic=%d)\n",
            ioapic->irqbase, inti, to.msg, to_apicid);
    ioapic_route_inti(ioapic, inti, to.msg, to_apicid);

    // enable
    ioapic_toggle_inti(ioapic, inti, true);

err_out:
    if(err_is_fail(err)){
        DEBUG_ERR(err, "add_mapping failed");
    }

}

static void ioapic_route_controller_bind_cb(void *st, errval_t err, struct int_route_controller_binding *b) {
    if(!err_is_ok(err)){
        debug_err(__FILE__,__FUNCTION__,__LINE__, err, "Bind failure\n");
        return;
    }

    b->rx_vtbl.add_mapping = add_mapping;

    // Register this binding for all controllers with class pcilnk
    const char * label = "";
    const char * ctrl_class = "ioapic";
    b->tx_vtbl.register_controller(b, NOP_CONT, label, ctrl_class);
}


#ifdef IOAPIC_DEBUG_FORWARD_ALL
static void debug_forward_irqs(void) {
    errval_t err;
    err = skb_execute_query("corename(0,_,apic(A)),writeln(A).");
    if(err_is_fail(err)){
        printf("ACPI id lookup failed");
        return;
    }

    int to_apicid = 0;
    err = skb_read_output("%d", &to_apicid);
    if(err_is_fail(err)){
        printf("ACPI id parse failed");
        return;
    }

    printf("DEBUG: Forwarding all IOAPIC interrupts to C0 (apic=%d)", to_apicid);
    for(int i=0; i < 5; i++){
        struct ioapic * ioapic = find_ioapic_by_index(i);
        if(ioapic != NULL && ioapic->initialized){
            for(int inti=0; inti<24;inti++){
                ioapic_route_inti(ioapic, inti, inti+32, to_apicid);
                ioapic_toggle_inti(ioapic, inti, true);
            }
        }
    } 
}
#endif // IOAPIC_DEBUG_FORWARD_ALL



errval_t ioapic_controller_client_init(void){
    // Connect to int route service
    iref_t int_route_service;
    errval_t err;
    err = nameservice_blocking_lookup("int_ctrl_service", &int_route_service);
    if(!err_is_ok(err)){
        debug_err(__FILE__,__FUNCTION__,__LINE__, err, "Could not lookup int_route_service\n");
        return err;
    }

    err = int_route_controller_bind(int_route_service, ioapic_route_controller_bind_cb, NULL, get_default_waitset(),
            IDC_BIND_FLAGS_DEFAULT);

    if(!err_is_ok(err)){
        debug_err(__FILE__,__FUNCTION__,__LINE__, err, "Could not bind int_route_service\n");
        return err;
    }

#ifdef IOAPIC_DEBUG_FORWARD_ALL
    debug_forward_irqs();
#endif

    return SYS_ERR_OK;
}
