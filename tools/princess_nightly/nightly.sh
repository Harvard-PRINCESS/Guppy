#!/bin/bash

# nightly.sh - nightly build script for Harvard-PRINCESS project
# usage: ./nightly.sh [git branch]

umask 022
ulimit -c 0
unset LANG
unset LC_ALL
unset LC_COLLATE
unset LC_CTYPE
unset LC_MESSAGES
unset LC_MONETARY
unset LC_NUMERIC
unset LC_TIME

PATH=/usr/local/bin:/usr/pkg/bin:/usr/bin:/bin
export PATH

RUN_DATE=`date +%Y-%m-%d-%a`
BUILD_FAILED=false
BUILD_START=$(date +%s)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# project/repository info
PROJECT_NAME=Guppy
GIT_REPO_URL=https://github.com/Harvard-PRINCESS/Guppy.git
GIT_BRANCH=$1

# nightly build tree
WORK_DIR=${HOME}/nightly
BUILD_DIR=${WORK_DIR}/build
GIT_REPO_DIR=${WORK_DIR}/src
BUILD=${BUILD_DIR}/nightly-$GIT_BRANCH-$RUN_DATE
BUILD_LOG=${BUILD}/nightly-log.out
BUILD_LOG_FULL=${BUILD}/nightly-log-full.out

# number of recent builds to keep around
MAX_BUILDS=3  

say() { echo "- $@"; }
sayheader() { echo "## $@"; }

dodiff() {
    diff -q "$1" "$2" >/dev/null
    return $?
}

gettime() {
    T1=$1
    T2=$(date +%s)
    expr "$T2" - "$T1"
}

# download fresh copy of repository 
gitupdate() {
	say 'Cloning a fresh copy of' ${PROJECT_NAME} 'Git repository.'

    rm -rf $GIT_REPO_DIR > /dev/null
	pushd ${WORK_DIR} > /dev/null
	git clone $GIT_REPO_URL src --quiet
	popd  > /dev/null

	# get new code
    say 'Checking out branch:' $GIT_BRANCH 
    pushd $GIT_REPO_DIR > /dev/null
    git fetch --all --quiet
    git checkout $GIT_BRANCH --quiet
    git pull origin $GIT_BRANCH --quiet
    popd > /dev/null
}

# remove all but last $MAX_BUILDS builds
cleanbuilds() {

	sayheader 'Purging all but' $MAX_BUILDS 'most-recent builds.'
    cd $BUILD_DIR
    while [ `ls -td * | wc -l` -gt $MAX_BUILDS ]; do 
        OLDEST=`ls -td nightly-* | tail -1`
        if [ -f $OLDEST ]; then 
            say "Removing old build directory $OLDEST"
            rm -rf $OLDEST
        fi
    done
}

dobuildplatform() {

    PLATFORM=$1
    TMP_FILE=$2

    sayheader 'Building' $PLATFORM
    START=$(date +%s)
    make -j 5 $PLATFORM &> $TMP_FILE
    if [ $? -ne 0 ]; then
        BUILD_FAILED=true
        cat $TMP_FILE | head -n 1000
    else
        say $PLATFORM 'build successful.'
    fi
    say $PLATFORM 'build time:' $(gettime $START) 'seconds'
    printf "\n##### ${PLATFORM} build logs:\n" > $BUILD_LOG_FULL
    cat $TMP_FILE  > $BUILD_LOG_FULL
}

# build project from source code
dobuild() {

	sayheader 'Building' ${PROJECT_NAME} '- branch' ${GIT_BRANCH}

    pushd $BUILD > /dev/null
    TMP_FILE=/tmp/nightly-$RUN_DATE.out

    # create Makefile
    say 'Running Hake.'
    START=$(date +%s)
    $GIT_REPO_DIR/hake/hake.sh -s $GIT_REPO_DIR -a armv7 -a x86_64 &> $TMP_FILE
    say 'Hake time:' $(gettime $START) 'seconds'

    if [ $? -ne 0 ]; then
        BUILD_FAILED=true && say "Hake run failed."
        cat $TMP_FILE | head -n 1000
    else
        say "Hake run successful."
    fi

    printf "\n##### Hake build logs:\n" > $BUILD_LOG_FULL
    cat $TMP_FILE  > $BUILD_LOG_FULL

    dobuildplatform X86_64_Basic $TMP_FILE
    dobuildplatform X86_64_Full $TMP_FILE
    dobuildplatform PandaboardES $TMP_FILE
    rm $TMP_FILE
    popd > /dev/null
}

# run project tests
dotest() {
	sayheader 'Testing' ${PROJECT_NAME} '-  branch' ${GIT_BRANCH}
    echo 'TODO: run harness here'
    return 0
}

# e-mail out build log
finish() {
    subject=$(echo  'Guppy nightly build summary - branch' ${GIT_BRANCH} '-' ${RUN_DATE})
    ${SCRIPT_DIR}/sendmail.py -f $BUILD_LOG \
        -s "$subject"
}

main() {

    mkdir -pv $BUILD > /dev/null
    touch $BUILD_LOG > /dev/null

    {
		sayheader $PROJECT_NAME 'nightly build'
        sayheader 'Git branch: ' $GIT_BRANCH
        sayheader 'Date: ' $RUN_DATE
        sayheader 'Host: ' $(hostname | sed 's,\..*,,;s,/,_,g')
        echo ""

        sayheader 'Downloading source code.'
		gitupdate
		cleanbuilds

		dobuild

        if [ $BUILD_FAILED = true ]; then
            sayheader 'Build failed - skipping tests.'
        else
            dotest
            sayheader 'Nightly build complete.'
    
        fi

	} 2>&1 | tee -a $BUILD_LOG

    sayheader 'Total execution time:' $(gettime $BUILD_START) 'seconds'
    sayheader 'Build logs are located in' $BUILD
    printf "\n##### Summary build log:\n" > $BUILD_LOG_FULL
    cat $BUILD_LOG  > $BUILD_LOG_FULL

	finish
}

main
exit 0
