#!/bin/bash
# nightly.sh - nightly build script for Harvard-PRINCESS project

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MAX_BUILDS=3
RUN_DATE=`date +%Y-%m-%d-%a`
WORK_DIR=${HOME}/nightly
BUILD_DIR=${WORK_DIR}/build
BUILD=${BUILD_DIR}/nightly-$RUN_DATE
MSG_FILE=${BUILD}/nightly-log.out
GIT_REPO_URL=https://github.com/Harvard-PRINCESS/Guppy.git
GIT_REPO_DIR=${WORK_DIR}/src
GIT_BRANCH=$1

say() { echo "* $@ *"; }

gitupdate() {

	# download repository if it doesn't exist
    if [ ! -d "$GIT_REPO_DIR" ]; then
        say 'Barrelfish repository does not exist... cloning'
        pushd ${WORK_DIR} > /dev/null
        git clone $GIT_REPO_URL src
        popd  > /dev/null
    fi

	# get new code
    pushd $GIT_REPO_DIR > /dev/null
    git fetch --all
    git checkout $GIT_BRANCH
    git pull origin $GIT_BRANCH
    popd > /dev/null
}

# remove all but last $MAX_BUILDS builds
cleanbuilds() {
    cd $BUILD_DIR
    while [ `ls -td * | wc -l` -gt $MAX_BUILDS ]; do 
        OLDEST=`ls -td nightly-* | tail -1`
        if [ -f $OLDEST ]; then 
            say "Removing old build directory $OLDEST"
            rm -rf $OLDEST
        fi
    done
}

# build Barrelfish OS for various architectures
dobuild() {

    pushd $BUILD > /dev/null
    TMP_FILE=/tmp/nightly-$RUN_DATE.out

    $GIT_REPO_DIR/hake/hake.sh -s $GIT_REPO_DIR -a armv7 -a x86_64 &> $TMP_FILE
    if [ $? -ne 0 ]; then
        cat $TMP_FILE
    fi

    make -j 5 X86_64_Full &> $TMP_FILE
    if [ $? -ne 0 ]; then
        cat $TMP_FILE
    fi

    make -j 5 PandaboardES &> $TMP_FILE
    if [ $? -ne 0 ]; then
        cat $TMP_FILE
    fi

    rm $TMP_FILE
    popd > /dev/null
}

# send script result e-mail
sendmail() {
    ${SCRIPT_DIR}/sendmail.py -f $MSG_FILE
}

main() {

    mkdir -pv $BUILD
    touch $MSG_FILE

    {
		say 'Harvard-PRINCESS Nightly Build ' $RUN_DATE
		say 'Downloading source code'
		gitupdate
		say 'Preparing build'
		cleanbuilds
		dobuild
		say 'Nightly build complete'
	} 2>&1 | tee -a $MSG_FILE

    #TODO: remove once merged into dev/master
    pushd $GIT_REPO_DIR 
    git checkout ahp_nightly_build
    popd

	sendmail

    #TODO: remove once merged into dev/master
    pushd $GIT_REPO_DIR 
    git checkout ahp_nightly_build
    popd
}

main
exit 0
