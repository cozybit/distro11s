#!/bin/bash

source `dirname $0`/common.sh

[ -d ${STAGING}/src ] || sudo mkdir ${STAGING}/src
sudo mount --bind ${DISTRO11S_SRC} ${STAGING}/src

CONFIG=${TOP}/board/${DISTRO11S_BOARD}/hostapd_build.config
if [ ! -e ${CONFIG} ]; then
	echo "No config for hostapd in ${CONFIG}, using default"
	CONFIG=defconfig
fi

HOSTAPD_SRC_DIR=${STAGING}/src/hostap/hostapd/
do_stamp_cmd hostapd.config cp ${CONFIG} ${HOSTAPD_SRC_DIR}/.config && echo "CONFIG_LIBNL32=y" >> ${HOSTAPD_SRC_DIR}/.config
HOSTAPD_MAKE_CMD="'cd /src/hostap/hostapd; make clean; CFLAGS=-I/usr/local/include/libnl3 make -j 2'"
do_stamp_cmd hostapd.make "sudo chroot ${STAGING} /bin/bash -c ${HOSTAPD_MAKE_CMD}"
HOSTAPD_INSTALL_CMD="'cd /src/hostap/hostapd; make install && cp hostapd.conf /etc/'"
do_stamp_cmd hostapd.make "sudo chroot ${STAGING} /bin/bash -c ${HOSTAPD_INSTALL_CMD}"

sudo umount ${STAGING}/src
