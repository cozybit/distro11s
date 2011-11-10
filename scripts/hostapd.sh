# Copyright © 2011 cozybit Inc.  All rights reserved.

#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/hostap/hostapd || exit 1

CONFIG=${TOP}/board/${DISTRO11S_BOARD}/hostapd_build.config
if [ ! -e ${CONFIG} ]; then
	echo "No config for hostapd in ${CONFIG}, using default"
	CONFIG=defconfig
fi
do_stamp_cmd hostapd.config cp ${CONFIG} ./.config && echo "CONFIG_LIBNL20=y" >> ./.config
do_stamp_cmd hostapd.make "make clean; PREFIX=${STAGING}/usr/local make -j ${DISTRO11S_JOBS};"
do_stamp_cmd hostapd.install DESTDIR=${STAGING} make install && cp hostapd.conf ${STAGING}/etc/
