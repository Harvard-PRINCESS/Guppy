##########################################################################
# Copyright (c) 2017, ETH Zurich.
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE file.
# If you do not find this file, copies can be found by writing to:
# ETH Zurich D-INFK, Haldeneggsteig 4, CH-8092 Zurich. Attn: Systems Group.
##########################################################################

import datetime
import tests
from common import TestCommon
from results import PassFailResult

@tests.add_test
class ProcMgmtTest(TestCommon):
    '''Process management service API. Requires at least 2 cores.'''
    name = "proc_mgmt_test"

    def setup(self, build, machine, testdir):
        super(ProcMgmtTest, self).setup(build, machine, testdir)
        self.test_timeout_delta = datetime.timedelta(seconds=15*60)

    def get_modules(self, build, machine):
        modules = super(ProcMgmtTest, self).get_modules(build, machine)
        n = 3
        for i in range(n):
            modules.add_module("proc_mgmt_test", ["core=3", str(i), str(n)])
            # modules.add_module("proc_mgmt_test", ["core=3", "1"])
        return modules

    def get_finish_string(self):
        return "TEST DONE"

    def process_data(self, testdir, rawiter):
        for line in rawiter:
            if line.startswith("FAIL:"):
                return PassFailResult(False)

        return PassFailResult(True)
