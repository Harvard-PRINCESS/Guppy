#!/bin/sh
# nightly-stub.sh - start the nightly build
# usage: bin/nightly-stub.sh
#
# Should be run in the top of the nightly build work area.
#
# This script does nothing but invoke bin/nightly.sh; however,
# if nightly.sh exits with the reserved code 19 it updates the
# script and settings files and tries again.
#

PATH=/usr/local/bin:/usr/pkg/bin:/usr/bin:/bin
export PATH

RESTART=
while :; do
    bin/nightly.sh $RESTART
    X=$?
    RESTART=restart
    case $X in
	0|1)
	    # routine success or failure
	    ;;
	19)
	    # update
	    cp trees/misc/nightly/nightly.sh bin/nightly.sh.new
	    mv bin/nightly.sh bin/nightly.sh.old
	    mv bin/nightly.sh.new bin/nightly.sh
	    rm -rf conf
	    mkdir conf
	    cp trees/misc/nightly/*.defs conf/
	    echo "Updated nightly.sh and conf/*.defs" | tee -a mailout >> log
	    continue
	    ;;
	29)
	    # failed hard
	    # This means nightly.sh didn't mail out, so cause
	    # cron to send mail to the job owner.
	    echo "nightly.sh failed badly - check the log"
	    ;;
    esac
    break
done
# sending exit codes back to cron is useless
exit 0
