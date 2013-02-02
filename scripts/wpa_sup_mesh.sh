#!/bin/bash

source `dirname $0`/common.sh

[ -d ${STAGING}/src ] || sudo mkdir ${STAGING}/src
sudo mount --bind ${DISTRO11S_SRC} ${STAGING}/src

echo "cd /src/wpa_sup_mesh/wpa_supplicant; make clean; CFLAGS=-I/usr/local/include/libnl3 make -j $DISTRO11S_JOBS; make install;" > ${STAGING}/wpa_sup_mesh.sh
chmod +x ${STAGING}/wpa_sup_mesh.sh

CONFIG=${TOP}/board/${DISTRO11S_BOARD}/wpa_sup_mesh_build.conf
if [ ! -e ${CONFIG} ]; then
	echo "No config for hostapd in ${CONFIG}, using default"
	CONFIG=defconfig
fi
do_stamp_cmd hostapd.config cp ${CONFIG} ${STAGING}/src/wpa_sup_mesh/wpa_supplicant/.config
do_stamp_cmd hostapd.make sudo chroot ${STAGING} /wpa_sup_mesh.sh

sudo umount ${STAGING}/src
rm -f ${STAGING}/wpa_sup_mesh.sh
