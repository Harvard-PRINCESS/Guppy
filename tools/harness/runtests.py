#!/usr/bin/env python

# run all of the passing tests from a platform testlist

import argparse
import os.path
import subprocess
import sys

from subprocess_timeout import wait_or_terminate

PASS_CODES, FAIL_CODES = ['P'], ['F', '?']
BUILD_DIR = './build'


def load_testlist(testfile):
    # return iterable of (testname, status) loaded from a test file
	tests = open(testfile, 'r').readlines()
	for test in tests:
		passes, name = test.split(',')
		if passes in FAIL_CODES:
			yield (name.rstrip(), False)
		elif passes in PASS_CODES:
			yield (name.rstrip(), True)
		else:
			msg = 'Invalid test status: test={} status={}'
			raise Exception(msg.format(name, status))


def build_scalebench_cmd(tests, args):

    options = []

    if args.runall:
        testspecs = [test for test, passes in tests]
    else:
        testspecs = [test for test, passes in tests if passes]

    options.append(('--keepgoing', ''))
    options.extend([('-t', test) for test in testspecs])
    options.extend([('-m', machine) for machine in args.machines])

    if os.path.isdir(BUILD_DIR):
        options.append(('-e', BUILD_DIR))
    else:
        options.append(('-B', BUILD_DIR))

    options = [s for opt in options for s in opt]
    
    cmd = ['./tools/harness/scalebench.py'] \
        + options + [args.sourcedir, args.resultsdir]
    return ' '.join(cmd)

def run_cmd(cmd):

    return subprocess.call(cmd, shell=True)

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
    returncode = run_cmd(cmd)
    if not returncode == 0:
        sys.exit(1)

if __name__ == '__main__':
	main()
