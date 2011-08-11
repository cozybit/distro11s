#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/kernel || exit 1

CONFIG=${TOP}/board/${DISTRO11S_BOARD}/${DISTRO11S_BOARD}_kernel.config
if [ ! -e ${CONFIG} ]; then
	echo "No config for kernel.  Expected ${CONFIG}."
	exit 1
fi
do_stamp_cmd kernel.config cp ${CONFIG} ./.config
do_stamp_cmd kernel.oldconfig "yes \"\" | make oldconfig"
do_stamp_cmd kernel.make make -j ${DISTRO11S_JOBS}
do_stamp_cmd kernel.install 'cp ${BOARD11S_KERNEL} ${DISTRO11S_OUT}/${DISTRO11S_BOARD}; cp ${BOARD11S_KERNEL} ${STAGING}/boot;'
INSTALL_MOD_PATH=${STAGING} do_stamp_cmd kernel.modules make -j ${DISTRO11S_JOBS} modules_install
