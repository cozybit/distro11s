# Copyright © 2011 cozybit Inc.  All rights reserved.

#!/bin/bash

source `dirname $0`/common.sh

SRC_PATH="${DISTRO11S_SRC}/kernel"
usage="$0 [-p <path>] [-h]"
while getopts "p:h" options; do
        case ${options} in
                p ) SRC_PATH=${OPTARG};;
                h ) echo Options:
                    echo "-p                        Path to the kernel source"
                    echo "-h                        Shows help"
                    exit 1;;
                * ) echo ${usage}
                    exit 1;;
        esac
done

Q pushd ${SRC_PATH} || exit 1

CONFIG=${TOP}/board/${DISTRO11S_BOARD}/${DISTRO11S_BOARD}_kernel.config
if [ ! -e ${CONFIG} ]; then
    echo "No config for kernel.  Expected ${CONFIG}."
    exit 1
fi

# set kernel extraversion to our git HEAD SHA-1
HEAD_SHA=`git log --oneline -n1 | awk '{print $1}'`
sed -i "s/^\(EXTRAVERSION =\($\| -rc[[:digit:]]*\)\).*$/\1-${HEAD_SHA}/" Makefile

do_stamp_cmd kernel.gdbinit 'echo "target remote localhost:1234
continue" > .gdbinit'
do_stamp_cmd kernel.config cp ${CONFIG} ./.config
do_stamp_cmd kernel.oldconfig "yes \"\" | make oldconfig"
do_stamp_cmd kernel.make make -j ${DISTRO11S_JOBS}
do_stamp_cmd kernel.install 'cp ${BOARD11S_KERNEL} ${DISTRO11S_OUT}/${DISTRO11S_BOARD}; cp ${BOARD11S_KERNEL} ${STAGING}/boot;'
INSTALL_MOD_PATH=${STAGING} do_stamp_cmd kernel.modules make -j ${DISTRO11S_JOBS} modules_install

# revert our Makefile change to make git happy
git checkout Makefile
