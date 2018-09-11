#!/usr/bin/env bash
# patch modified from: https://itefix.net/content/puttygen-patch-entering-passphrases-command-line

# this script assumes the following:
# - you are running ubuntu 16 or 18 (may work on older versions, not tested)
# - you have wget installed
# - you have tar installed
# - you have patch/diff installed
# - you have gcc/make/build-essentials installed
# - you have fpm installed
# - you have reprepro installed and configured

# set variables
PUTTY_VERSION=0.70
PUTTY_BASENAME="putty-$PUTTY_VERSION"
PUTTY_ARCHIVE="$PUTTY_BASENAME.tar.gz"
CWD=$PWD
COUNTER_FILE="counter.tmp"
COUNT=0
PUTTY_DESC="putty-tools with puttygen allowing password entry via cli"
REPREPRO_DIR="/srv/reprepro/ubuntu/"
PACKAGE_NAME="putty-tools-pwd"

# start
echo "--- PUTTYGEN CLI PASSWORD PATCH ---"

# function to bail on failed subcommands
bail() {
    echo "$*"
    cleanup
    exit 1
}

# function to perform cleanup
cleanup() {
    echo "cleaning up"
    rm -rf $CWD/build
    unset PUTTY_VERSION
    unset PUTTY_BASENAME
    unset PUTTY_ARCHIVE
    unset CWD
    unset COUNTER_FILE
    unset COUNT
    unset PUTTY_DESC
    unset REPREPRO_DIR
    unset PACKAGE_NAME
    unset BDIR
    unset COUNT
    unset FPM_FILE
}

# create workdir for easy cleanup
mkdir -p $CWD/build
cd $CWD/build
BDIR=$PWD

# download latest putty
echo "downloading putty-tools version $PUTTY_VERSION"
wget -q -O $BDIR/$PUTTY_ARCHIVE "https://the.earth.li/~sgtatham/putty/latest/$PUTTY_ARCHIVE" || bail "failed to download putty archive"

# extract putty into subdirectory
echo "extracting archive"
tar -xzf $BDIR/$PUTTY_ARCHIVE || bail "failed to extract putty archive; check write permissions and if your disk is full"

# move to directory where to apply patch
cd $BDIR/$PUTTY_BASENAME

# apply patch
patch < $CWD/cmdgen.option-N.patch || bail "could not patch cmggen.c; maybe the file has changed?"

# configure build && make without install
echo "configuring and making build"
cd $BDIR/$PUTTY_BASENAME/unix/
./configure > $CWD/configure.log 2>&1 || bail "could not configure puttytools"
make > $CWD/make.log 2>&1 || bail "could not make puttytools"

# install to tmp folder
echo "build to clean temp directory"
mkdir -p $BDIR/tmpbuild
make DESTDIR=$BDIR/tmpbuild/ install > $CWD/make-install.log 2>&1 || bail "could not make install puttytools"

# determine iteration
if [ ! -f $CWD/$COUNTER_FILE ]; then
    echo "fpm iteration file not found; creating new one"
else
    COUNT=`cat $CWD/$COUNTER_FILE`
    echo "fpm iteration file found; previous iteration was $COUNT"
fi

# increment and write to the file
((COUNT++))
echo "$COUNT" > $CWD/$COUNTER_FILE
echo "current fpm iteration is at: $COUNT"

# determine fpm package filename
FPM_FILE=$PACKAGE_NAME"_"$PUTTY_VERSION"-"$COUNT"_amd64.deb"

# create deb package and move file
cd $BDIR
fpm -s dir -t deb -C $BDIR/tmpbuild/ --name $PACKAGE_NAME --version $PUTTY_VERSION --iteration $COUNT --description "$PUTTY_DESC" > $CWD/fpm.log 2>&1 || bail "could not package patched puttytools; is fpm installed?"
mv $BDIR/$FPM_FILE $CWD/$FPM_FILE

# add package to reprepro for xenial
# "bionic" is the new lsb_release for Ubuntu 18.x but this script does not support it yet
reprepro -b $REPREPRO_DIR includedeb xenial $CWD/$FPM_FILE || bail "could not import deb archive in reprepro; is reprepro installed?"

# cleanup
cleanup