#!/usr/bin/env python

"""
runtest.py - run all of the passing tests from a platform testlist

A testlist is a CSV of the form <status>,<name> for a specific platform. If
status is in RUN_CODES then this test both passes *and will get executed* when
you run this script. If status is in PASS_CODES this means that it passes on
the architecture. If status is in FAIL_CODES then it fails on this platform and
won't get run.
"""

import argparse
import os.path
import subprocess
import sys

from subprocess_timeout import wait_or_terminate

PASS_CODES, RUN_CODES, FAIL_CODES = ['P', 'R'], ['R'], ['F', '?']
BUILD_DIR = './build'


def load_testlist(testfile):
    # return iterable of (testname, status) loaded from a test file
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
    
    cmd = ['./tools/harness/scalebench.py'] \
        + options + [args.sourcedir, args.resultsdir]
    print ' '.join(cmd)
    return ' '.join(cmd)


def main():

    script_desc = 'Run list of tests against Barrelfish OS'
    parser = argparse.ArgumentParser(description=script_desc)
    parser.add_argument('-f', '--testfile', type=str, dest='testfile',
                        help='name of testfile to run', 
                        default='tools/harness/testlist/qemu2_x86_64.test')
    parser.add_argument('-r', '--resultsdir', type=str, default='./results',
                        help='test result directory',  dest='resultsdir')
    parser.add_argument('-s', '--sourcedir', type=str,
                        help='source directory', default='.', dest='sourcedir')
    parser.add_argument('--runall', action='store_true', dest='runall',
                        help='run all tests instead of just passing ones')
    parser.add_argument('-m', '--machine', action='append', default=['qemu2'],
                        dest='machines', help='victim machines to use')
    args = parser.parse_args()
	
    if not os.path.isfile(args.testfile):
        msg = 'Test file does not exist: {}'
        raise Exception(msg.format(args.testfile))

    tests = load_testlist(args.testfile)
    cmd = build_scalebench_cmd(tests, args)
    returncode = subprocess.call(cmd, shell=True, stderr=subprocess.STDOUT)
    if not returncode == 0:
        sys.exit(1)

if __name__ == '__main__':
	main()
