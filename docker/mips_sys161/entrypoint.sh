#!/bin/bash

set -e

mkdir /usr/local/barrelfish/build
cd /usr/local/barrelfish/build
../hake/hake.sh -s .. -a mips > $CIRCLE_ARTIFACTS/hakelog.out 2> $CIRCLE_ARTIFACTS/hakelog.err
