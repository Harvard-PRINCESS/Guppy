#!/usr/bin/env python

"""
runtest.py - run all of the passing tests from a platform testlist

A testlist is a CSV of the form <status>,<name> for a specific platform.
* If status is in RUN_CODES then this test both passes *and will get executed*
when you run this script.
* If status is in PASS_CODES this means that it passes on the architecture, but
will not get run.
* If status is in FAIL_CODES then it fails on this platform and won't get run.
'F' is fail, '?' is did not terminate.
"""

import argparse
import os.path
import subprocess
import sys

RUN_CODES, PASS_CODES, FAIL_CODES = ['R'], ['P', 'R'], ['F', '?']
BUILD_DIR = './build'


def load_testlist(testfile):
    """
    return iterable of (testname, status) loaded from a test file
    """

    tests = open(testfile, 'r').readlines()
    for test in tests:
        passes, name = test.split(',')
        if passes in RUN_CODES:
            yield (name.rstrip(), True)
        elif passes in FAIL_CODES or passes in PASS_CODES:
            yield (name.rstrip(), False)
        else:
            msg = 'Invalid test status: test={} status={}'
            raise Exception(msg.format(name, passes))


def build_scalebench_cmd(tests, args):
    """
    return test harness shell command as a string, to be run from repository
    root
    """

    options = []

    if args.runall:
        testspecs = [test for test, passes in tests]
    else:
        testspecs = [test for test, passes in tests if passes]

    options.append(('--keepgoing', ''))
    options.append(('--verbose', ''))
    options.extend([('-t', test) for test in testspecs])
    options.extend([('-m', machine) for machine in args.machines])

    if os.path.isdir(BUILD_DIR):
        options.append(('-e', BUILD_DIR))
    else:
        options.append(('-B', BUILD_DIR))

    options = [s for opt in options for s in opt]

    cmd = ['./tools/harness/scalebench.py']
    cmd.extend(options)
    cmd.extend([args.sourcedir, args.resultsdir])

    return ' '.join(cmd)


def main():

    script_desc = 'Run list of tests against Barrelfish OS'
    parser = argparse.ArgumentParser(description=script_desc)
    parser.add_argument('-f', '--testfile', type=str, dest='testfile',
                        help='name of testfile to run',
                        default='tools/harness/testlist/qemu2_x86_64.test')
    parser.add_argument('-r', '--resultsdir', type=str, default='./results',
                        help='test result directory', dest='resultsdir')
    parser.add_argument('-s', '--sourcedir', type=str,
                        help='source directory', default='.', dest='sourcedir')
    parser.add_argument('--runall', action='store_true', dest='runall',
                        help='run all tests instead of just passing ones')
    parser.add_argument('-m', '--machine', action='append', default=[],
                        dest='machines', help='victim machines to use')
    args = parser.parse_args()

    if not os.path.isfile(args.testfile):
        msg = 'Test file does not exist: {}'
        raise Exception(msg.format(args.testfile))

    # XXX ELU hack to not run qemu2 when I -do- give a machine list
    # is there no way to make appending work decently?
    if not args.machines: # i.e. the list is empty
        args.machines.append('qemu2')

    tests = load_testlist(args.testfile)
    cmd = build_scalebench_cmd(tests, args)
    returncode = subprocess.call(cmd, shell=True, stderr=subprocess.STDOUT)
    sys.exit(returncode)


if __name__ == '__main__':
    main()
