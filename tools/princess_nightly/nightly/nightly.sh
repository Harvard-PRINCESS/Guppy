#!/bin/sh
# nightly.sh - nightly build script for GOAT project
# usage: bin/nightly.sh [restart]

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_UPDATE=19
EXIT_DIEDHORRIBLY=29

umask 022
ulimit -c 0
PATH=/usr/local/bin:/usr/pkg/bin:/usr/bin:/bin
export PATH
unset LANG
unset LC_ALL
unset LC_COLLATE
unset LC_CTYPE
unset LC_MESSAGES
unset LC_MONETARY
unset LC_NUMERIC
unset LC_TIME

if [ x"$1" = xrestart ]; then
    RESTARTED=1
else
    RESTARTED=0
fi

# Dump everything into the build log. Some things go to the mailed-out
# log. (Timings go only to the mailed-out log.)

say() {
    echo "$@" | tee -a mailout
}

if [ $RESTARTED = 1 ]; then
    exec >> log 2>&1
    echo "Build restarted." | tee -a mailout
    say
else
    exec > log 2>&1
    rm -f mailout
    touch mailout
    date +%s > startstamp
fi
HAVEMAILHEADER=0
DIDTHEMAIL=0

MYHOST="$(hostname | sed 's,\..*,,;s,/,_,g')"
if [ ! -f conf/"$MYHOST".defs ]; then
    say "No configuration for $MYHOST; starting with defaults"
    CONF_HGDIR=/home/syrah/hg
    CONF_MAILFROM="$(whoami)@$(hostname)"
    CONF_MAILTO="$(whoami)"
    CONF_SENDER=$CONF_MAILFROM
    DOUPDATE=1
else
    say "Building on $MYHOST"
    . conf/"$MYHOST".defs
    DOUPDATE=0
fi

gettime() {
    T1=$1
    T2=$(date +%s)
    expr "$T2" - "$T1"
}

############################################################
# first, clone the trees.

checkout() {
    # Get a tree *without* a mercurial repository; this both saves
    # space and discourages people from developing in the nightly
    # build area.

    # XXX or not. FUTURE

    #NAME=$(basename "$1")
    #mkdir "$NAME"
    #HERE=$(pwd)
    #(cd "$1" && hg archive -r tip "$HERE/$NAME")

    echo "hg -q clone $1"
    hg -q clone "$1"
    return $?
}

checkoutgit() {
    # I don't know how to get a git tree without a repository. But
    # it would be better to have one. XXX

    echo "git clone $1"
    git clone "$1"
    return $?
}

#
# We keep the last successful build in trees.save.
#
# If the build succeeds, it replaces trees.save.
# Otherwise it gets left in trees.bad.
#
# If trees.bad already exists, it means the last build failed. Delete
# it. If (instead) trees already exists, it means the last build was
# interrupted.  Delete that too.
#
# Don't do this again if we restart.
#

if [ $RESTARTED = 0 ]; then
    if [ -d trees.bad ]; then
	mv trees.bad deleteme.$$
    fi
    if [ -d trees ]; then
	mv trees deleteme.$$
    fi
    if [ -d deleteme.$$ ]; then
	rm -rf deleteme.$$ &
    fi
fi

die() {
    say "Failed."
    mv trees trees.bad
    if [ $HAVEMAILHEADER = 0 ]; then
	exit $EXIT_DIEDHORRIBLY
    fi
    $CONF_SENDMAIL -f $CONF_SENDER $CONF_MAILTO < mailout
    exit $EXIT_FAILURE
}

finish() {
    $CONF_SENDMAIL -f $CONF_SENDER $CONF_MAILTO < mailout
    rm mailout
    if [ -d trees.save ]; then
	mv trees.save deleteme.$$
	rm -rf deleteme.$$ &
    fi
    mv trees trees.save
    exit $EXIT_SUCCESS
}

#
# check out the misc tree
# (only the first time through)
#
if [ $RESTARTED = 0 ]; then
    mkdir trees || exit $EXIT_DIEDHORRIBLY  # *not* die()
    START=$(date +%s)
    say "Cloning goatmisc..."
    cd trees
    checkout "$CONF_HGDIR"/goat/misc || die
    cd ..
    echo $(gettime $START) > clonemisctime
fi

#
# check if we need to update
#

say "Checking the scripts"

dodiff() {
    diff -q "$1" "$2" >/dev/null 2>&1
    return $?
}

if dodiff bin/nightly-stub.sh trees/misc/nightly/nightly-stub.sh; then
    :
else
    say "WARNING: nightly-stub.sh is out of date"
    say "WARNING: you need to fix this by hand"
fi
if dodiff bin/nightly.sh trees/misc/nightly/nightly.sh; then
    :
else
    say " * nightly.sh is out of date"
    DOUPDATE=1
fi
if [ -d conf ]; then
    for D in trees/misc/nightly/*.defs; do
	D1=$(basename "$D")
	if [ -f conf/"$D1" ]; then
	    if dodiff conf/"$D1" "$D"; then
		:
	    else
		say " * conf/$D1 is out of date"
		DOUPDATE=1
	    fi
	else
	    say " * conf/$D1 is missing"
	    DOUPDATE=1
	fi
    done  
fi

# Avoid infinite loop.
if [ ! -f trees/misc/nightly/"$MYHOST".defs ]; then
    say "*** No configuration for $MYHOST in master tree ***"
    die
fi

if [ $DOUPDATE = 1 ]; then
    if [ $RESTARTED = 1 ]; then
	say "*** Attempted to restart more than once ***"
	die
    fi
    # tell nightly-stub to update
    exit $EXIT_UPDATE
fi

#
# Now we can clone the other trees.
#

START=$(date +%s)
say "Cloning the other trees..."
cd trees
checkout "$CONF_HGDIR"/goat/libgoatdummy
checkout "$CONF_HGDIR"/goat/goatdb
checkout "$CONF_HGDIR"/pql/pqlbrl
checkout "$CONF_HGDIR"/pql/pqqolo
cd ..
CLONEMISCTIME=$(cat clonemisctime)
rm clonemisctime
CLONETIME=$(expr $CLONEMISCTIME + $(gettime $START))
echo "Time spent cloning: $CLONETIME seconds" >> mailout

START=$(date +%s)
say "Cloning LLAMA from github..."
cd trees
checkoutgit https://github.com/goatdb/llama
cd ..
GITCLONETIME=$(gettime $START)
echo "Time spent cloning with git: $GITCLONETIME seconds" >> mailout

# hg identify all the trees
say "Versions:"
for T in pqlbrl pqqolo libgoatdummy goatdb misc; do
    (cd trees/$T && echo -n "   $T " && hg identify) | tee -a mailout
done
for T in llama; do
    (cd trees/$T && echo -n "   $T " && git rev-parse HEAD) | tee -a mailout
done

############################################################
# check the build configuration

#
# This comes after cloning because the first run of a new build
# doesn't necessarily have any of this set until conf/ gets updated.
#

say "Checking configuration..."

# Mail
case "$CONF_MAILFROM" in
    *@*) ;;
    "") say "   CONF_MAILFROM must be set"; die;;
    *) say "   CONF_MAILFROM not a mail address"; die;;
esac
case "$CONF_MAILTO" in
    *@*) ;;
    "") say "   CONF_MAILTO must be set"; die;;
    *) say "   CONF_MAILTO not a mail address"; die;;
esac
case "$CONF_SENDER" in
    *@*) ;;
    "") say "   CONF_SENDER must be set"; die;;
    *) say "   CONF_SENDER not a mail address"; die;;
esac

#
# Generate the mail header now that we've validated the addresses.
#

mv mailout mailout.tmp

cat > mailout <<EOF
From: $CONF_MAILFROM (buildygoat)
To: $CONF_MAILTO (Goat committers)
Subject: $MYNAME Goat nightly results for $(date)
Sender: $CONF_SENDER

EOF

cat mailout.tmp >> mailout
rm mailout.tmp
HAVEMAILHEADER=1

#
# Check the rest of the configuration.
#
BADCONFIG=0

# Subsystems

case "$ENABLE_PQLBRL" in
    yes|no) ;;
    "") ENABLE_PQLBRL=yes;;
    *) say "   yes/no setting ENABLE_PQLBRL set to $ENABLE_PQLBRL"
       BADCONFIG=1
    ;;
esac
case "$ENABLE_PQQOLO" in
    yes|no) ;;
    "") ENABLE_PQQOLO=yes;;
    *) say "   yes/no setting ENABLE_PQQOLO set to $ENABLE_PQQOLO"
       BADCONFIG=1
    ;;
esac
case "$ENABLE_LLAMA" in
    yes|no) ;;
    "") ENABLE_LLAMA=yes;;
    *) say "   yes/no setting ENABLE_LLAMA set to $ENABLE_LLAMA"
       BADCONFIG=1
    ;;
esac
case "$ENABLE_GOAT" in
    yes|no) ;;
    "") ENABLE_GOAT=yes;;
    *) say "   yes/no setting ENABLE_GOAT set to $ENABLE_GOAT"
       BADCONFIG=1
    ;;
esac
case "$ENABLE_FLUTE" in
    yes|no) ;;
    "") ENABLE_FLUTE=yes;;
    *) say "   yes/no setting ENABLE_FLUTE set to $ENABLE_FLUTE"
       BADCONFIG=1
    ;;
esac
case "$ENABLE_IGOR" in
    yes|no) ;;
    "") ENABLE_IGOR=yes;;
    *) say "   yes/no setting ENABLE_IGOR set to $ENABLE_IGOR"
       BADCONFIG=1
    ;;
esac

# Make

case "$CONF_BMAKE" in
    *) ;;
    "") case "$(uname)" in
	    NetBSD|FreeBSD|OpenBSD|DragonFly) CONF_BMAKE=make;;
	    *) CONF_BMAKE=bmake;;
	esac
    ;;
esac
case "$CONF_GMAKE" in
    *) ;;
    "") case "$(uname)" in
	    Linux) CONF_GMAKE=make;;
	    *) CONF_GMAKE=gmake;;
	esac
    ;;
esac

# Programs

case "$HAVE_AGCL" in
    yes) CONF_AGCL=agcl;;
    no) CONF_AGCL=true;;
    "") say "   HAVE_AGCL must be set to yes or no"
        BADCONFIG=1
    ;;
    *) say "   yes/no setting HAVE_AGCL set to $HAVE_AGCL"
       BADCONFIG=1
    ;;
esac
case "$HAVE_GHC" in
    yes) unset CONF_INSTALLED_PQQOLO;;
    no) ENABLE_PQQOLO=no;;
    "") say "   HAVE_GHC must be set to yes or no"
        BADCONFIG=1
    ;;
esac
case "$HAVE_OBJCOPY" in
    yes|"") CONF_OBJCOPY=objcopy;;
    no) CONF_OBJCOPY=false; ENABLE_PQLBRL=no;;
    *) say "   yes/no setting HAVE_OBJCOPY set to $HAVE_OBJCOPY"
       BADCONFIG=1
    ;;
esac

case "$CONF_CC" in
    "") CONF_CC=cc;;
    *) ;;
esac
case "$CONF_CXX" in
    "") CONF_CXX=c++;;
    *) ;;
esac
case "$CONF_RANLIB" in
    "") CONF_RANLIB=true;;
    *) ;;
esac
case "$CONF_SENDMAIL" in
    "") if [ -x /usr/sbin/sendmail ]; then
	    CONF_SENDMAIL=/usr/sbin/sendmail
	else
	    say "   CONF_SENDMAIL not set and /usr/sbin/sendmail not found"
	    BADCONFIG=1
	fi
	;;
    *) ;;
esac

case "$CONF_INSTALLED_PQQOLO" in
    /*) ;;
    "") ;;
    *) say "   CONF_INSTALLED_PQQOLO should be an absolute path"
       BADCONFIG=1
    ;;
esac

# Libraries
case "$CONF_BDB_CFLAGS" in
    *) ;;
    "") say "   CONF_BDB_CFLAGS must be set"
        BADCONFIG=1
    ;;
esac
case "$CONF_BDB_LDFLAGS" in
    *) ;;
    "") say "   CONF_BDB_LDFLAGS must be set"
        BADCONFIG=1
    ;;
esac
case "$CONF_BDB_LIBS" in
    *) ;;
    "") say "   CONF_BDB_LIBS must be set"
        BADCONFIG=1
    ;;
esac

# Flags

case "$CONF_DEBUG" in
    -*) ;;
    "") say "   CONF_DEBUG must be set"
        BADCONFIG=1
    ;;
    *) say "   Warning: CONF_DEBUG does not look like an option";;
esac

# Collect all the complaints before choking
if [ $BADCONFIG = 1 ]; then
    die
fi

############################################################
# establish the installed tree

#
# We will install some things (the libraries that other things
# need to build against) into trees/installed.
# 

mkdir trees/installed || die

CONF_DESTDIR=
CONF_PREFIX="$(pwd)/trees/installed"

############################################################
# configure the trees

#
# We need to generate defs.mk files for the following places:
#
# pqlbrl
# pqqolo
# libgoatdummy
# goatdb
# misc/pqlexec
# (maybe misc/igor, but for now I don't know how to configure it)
# misc/test
#

#
# configuring pqlbrl
#
# pqlbrl needs:
#   paths - DESTDIR PREFIX
#   progs - CC CXX LD AR RANLIB OBJCOPY AGCL
#   flags - DEBUG
#
cat > trees/pqlbrl/defs.mk <<EOF
DESTDIR=$CONF_DESTDIR
PREFIX=$CONF_PREFIX
CC=$CONF_CC
CXX=$CONF_CXX
LD=ld
AR=ar
RANLIB=$CONF_RANLIB
OBJCOPY=$CONF_OBJCOPY
AGCL=$CONF_AGCL
DEBUG=$CONF_DEBUG
EOF
if [ "x$EXTRACONF_PQLBRL" != x ]; then
    echo "$EXTRACONF_PQLBRL" >> trees/pqlbrl/defs.mk
fi

#
# configuring pqqolo
#
# pqqolo needs:
#    paths - DESTDIR PREFIX
#    progs - CC AGCL
#    flags - OPT (same as DEBUG)
#
cat > trees/pqqolo/defs.mk <<EOF
PREFIX=$CONF_PREFIX
DESTDIR=$CONF_DESTDIR
CC=$CONF_CC
AGCL=$CONF_AGCL
OPT=$CONF_DEBUG
EOF
if [ "x$EXTRACONF_PQQOLO" != x ]; then
    echo "$EXTRACONF_PQQOLO" >> trees/pqqolo/defs.mk
fi

#
# configuring libgoatdummy
#
# libgoatdummy needs:
#    paths - DESTDIR PREFIX
#    progs - CC CXX LD AR RANLIB OBJCOPY
#    libs - BDB_CFLAGS BDB_LDFLAGS BDB_LIBS
#    flags - DEBUG

cat > trees/libgoatdummy/defs.mk <<EOF
PREFIX=$CONF_PREFIX
DESTDIR=$CONF_DESTDIR
CC=$CONF_CC
CXX=$CONF_CXX
LD=ld
AR=ar
RANLIB=$CONF_RANLIB
OBJCOPY=$CONF_OBJCOPY
BDB_CFLAGS=$CONF_BDB_CFLAGS
BDB_LDFLAGS=$CONF_BDB_LDFLAGS
BDB_LIBS=$CONF_BDB_LIBS
DEBUG=$CONF_DEBUG
EOF

#
# configuring goatdb
#
# for now, nothing

#
# configuring pqlexec
#
# pqlexec needs:
#    paths - DESTDIR PREFIX
#    progs - CC CXX LD AR RANLIB OBJCOPY AGCL
#    libs - BDB_CFLAGS BDB_LDFLAGS BDB_LIBS
#    flags - DEBUG
cat > trees/misc/pqlexec/defs.mk <<EOF
PREFIX=$CONF_PREFIX
DESTDIR=$CONF_DESTDIR
CC=$CONF_CC
CXX=$CONF_CXX
LD=ld
AR=ar
RANLIB=$CONF_RANLIB
OBJCOPY=$CONF_OBJCOPY
AGCL=$CONF_AGCL
BDB_CFLAGS=$CONF_BDB_CFLAGS
BDB_LDFLAGS=$CONF_BDB_LDFLAGS
BDB_LIBS=$CONF_BDB_LIBS
DEBUG=$CONF_DEBUG
EOF
if [ "x$EXTRACONF_PQLEXEC" != x ]; then
    echo "$EXTRACONF_PQLEXEC" >> trees/pqlexec/defs.mk
fi

#
# configuring igor
#
# for now, nothing

#
# configuring test
#
# test needs:
#    nothing by default
cat > trees/misc/test/defs.mk <<EOF
EOF
case "$CONF_INSTALLED_PQQOLO" in
    "") ;;
    *)
	echo "PQQOLO=$CONF_INSTALLED_PQQOLO" >> trees/misc/test/defs.mk
	;;
esac

############################################################
# compiling

#
# If enabled, compile in the following order:
#   pqlbrl
#   pqqolo
#   llama
#   libgoatdummy
#   goatdb
#   misc/barrel
#   misc/pqlexec (flute)
#   misc/igor
#

sep() {
    echo "************************************************************"
}

sep

# dobuild make yes/no name dir
dobuild() {
    if [ "$2" = yes ]; then
	say "Building $3"
	START=$(date +%s)
	if (cd "$4" && "$1"); then
	    echo "Build time: $(gettime $START) seconds" >> mailout
	else
	    echo "Build failed after $(gettime $START) seconds" >> mailout
	    DIED=1
	fi
	sep
    else
	say "Skipping $3"
    fi
}

# doinst make yes/no name dir
doinst() {
    if [ "$2" = yes ]; then
	say "Installing $3"
	START=$(date +%s)
	if (cd "$4" && "$1" install); then
	    echo "Install time: $(gettime $START) seconds" >> mailout
	else
	    echo "Install failed after $(gettime $START) seconds" >> mailout
	    DIED=1
	fi
	sep
    else
	say "Skipping $3"
    fi
}

bbuild() {
    dobuild "$CONF_BMAKE" "$1" "$2" "$3"
}

gbuild() {
    dobuild "$CONF_GMAKE" "$1" "$2" "$3"
}

binst() {
    doinst "$CONF_BMAKE" "$1" "$2" "$3"
}

ginst() {
    doinst "$CONF_GMAKE" "$1" "$2" "$3"
}

bbuild "$ENABLE_PQLBRL" "PQLBRL" trees/pqlbrl
bbuild "$ENABLE_PQQOLO" "pqqolo" trees/pqqolo
gbuild "$ENABLE_LLAMA" "llama" trees/llama
bbuild "$ENABLE_GOAT" "libgoatdummy" trees/libgoatdummy
binst "$ENABLE_GOAT" "libgoatdummy" trees/libgoatdummy
bbuild "$ENABLE_GOAT" "GoatDB" trees/goatdb
bbuild "$ENABLE_PQLBRL" "barrel" trees/misc/barrel
bbuild "$ENABLE_FLUTE" "flute" trees/misc/pqlexec

gbuild "$ENABLE_IGOR" "IGOR" trees/misc/igor

if [ x$DIED = x1 ]; then
    echo "Builds failed; not running tests" >> mailout
    die
fi

############################################################
# testing

#
# If enabled, test in the following order:
#   pqlbrl
#   pqqolo
#   (not llama yet)
#   libgoatdummy
#   goatdb
#   misc/test/databases
#   misc/test/barrel
#   misc/test/flute
#   misc/test/woodwinds
#

# dotest name dir makeargs
dotest() {
    say "$1"
    START=$(date +%s)
    (cd $2 && $CONF_BMAKE $3) || die
    echo "Run time: $(gettime $START) seconds" >> mailout
    sep
}

if [ "$ENABLE_PQLBRL" = yes ]; then
    dotest "Testing PQLBRL" trees/pqlbrl test
fi

if [ "$ENABLE_PQQOLO" = yes ]; then
    dotest "Testing pqqolo" trees/pqqolo test
fi

if [ "$ENABLE_GOAT" = yes ]; then
    dotest "Testing GoatDB" trees/goatdb test
fi

#
# XXX this is messy and the logic for switching these on and off
# should go into the test tree itself.
#
if [ "$ENABLE_PQLBRL" = yes ]; then
    dotest "Building barrel databases" trees/misc/test/databases PROGS=barrel
fi
if [ "$ENABLE_FLUTE" = yes ]; then
    dotest "Building flute databases" trees/misc/test/databases PROGS=flute
fi
if [ "$ENABLE_PQLBRL" = yes ]; then
    dotest "Testing barrel" trees/misc/test/barrel all
fi
if [ "$ENABLE_FLUTE" = yes ]; then
    dotest "Testing flute" trees/misc/test/flute all
fi
TEST_WOODWINDS=yes
if [ "$ENABLE_FLUTE" = no ]; then
    TEST_WOODWINDS=no
fi
if [ "$ENABLE_PQQOLO" = no ]; then
    if [ x"$CONF_INSTALLED_PQQOLO" = x ]; then
	TEST_WOODWINDS=no
    fi
fi
if [ "$TEST_WOODWINDS" = yes ]; then
    dotest "Testing woodwinds" trees/misc/test/woodwinds all
fi

############################################################
# save the log

START=$(cat startstamp)
rm startstamp
echo "Total elapsed time: $(gettime $START) seconds" >> mailout

if [ ! -d logs ]; then
    mkdir logs
    (
	cd logs &&
	hg init &&
	touch buildlog &&
	hg add buildlog &&
	hg commit -u buildygoat -m "Seed the build log"
    )
fi

# if anything breaks after this point, we don't want it writing into
# the log during hg commit
exec >> mailout 2>&1

mv log logs/buildlog
touch logs/buildlog
(cd logs && hg diff) > logdiff
(cd logs && hg commit -u buildygoat -m "Build log for $(date)")

LINES=$(cat logdiff | wc -l)
if [ $LINES = 0 ]; then
    # nothing
elif [ $LINES -gt 1000 ]; then
    echo "First 1000 lines of log diff:" >> mailout
    head -1000 logdiff >> mailout
else
    echo "Log diffs:" >> mailout
    cat logdiff >> mailout
fi
rm logdiff


############################################################
# done; mail out the results

finish
