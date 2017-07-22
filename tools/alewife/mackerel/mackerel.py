#!/usr/bin/env python

import json

ast = {
    "filename": "test_register.dev",
    "description": "dummy device with some registers",
    "args": [
        { "arg": "addr" },
        { "arg": "base" },
    ],
    "devices": [
        {
            "name": "test_register",
	    "description": "test device with registers",
            "bit_order": "lsbfirst",
            "registers": [
                {
                    "name": "alpha",
                    "description": "alpha register",
                    "space": "rw",
                    "args": "addr(base, 0x0280)",
                },
                {
                    "name": "beta",
                    "description": "beta register",
                    "space": "rw",
                    "args": "addr(base, beta)",
                },

            ]
        }
    ],
}

print json.dumps(ast)

