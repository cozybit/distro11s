#!/bin/bash

source `dirname $0`/common.sh

[ -d ${STAGING}/src ] || sudo mkdir ${STAGING}/src
sudo mount --bind ${DISTRO11S_SRC} ${STAGING}/src

echo "cd /src/libnl; ./autogen.sh" > ${STAGING}/libnl.sh
chmod +x ${STAGING}/libnl.sh
do_stamp_cmd libnl.autogen sudo chroot ${STAGING} /libnl.sh
echo "cd /src/libnl; ./configure --prefix=/usr/local" > ${STAGING}/libnl.sh
chmod +x ${STAGING}/libnl.sh
do_stamp_cmd libnl.configure sudo chroot ${STAGING} /libnl.sh
echo "cd /src/libnl; make clean; make" > ${STAGING}/libnl.sh
chmod +x ${STAGING}/libnl.sh
do_stamp_cmd libnl.make sudo chroot ${STAGING} /libnl.sh
echo "cd /src/libnl; make install" > ${STAGING}/libnl.sh
chmod +x ${STAGING}/libnl.sh
do_stamp_cmd libnl.install sudo chroot ${STAGING} /libnl.sh

sudo umount ${DISTRO11S_SRC}
rm -f ${STAGING}/libnl.sh
