#!/bin/bash

source `dirname $0`/common.sh

sudo mkdir ${STAGING}/src
sudo mount --bind ${DISTRO11S_SRC} ${STAGING}/src

#Q pushd ${DISTRO11S_SRC}/authsae || exit 1

echo "cd /src/authsae; rm -rf build; mkdir build; cd build; export CFLAGS=\"${CFLAGS} -D_GNU_SOURCE\"; cmake -DSYSCONF_INSTALL_DIR=/etc -DCMAKE_INSTALL_PREFIX=/usr/local ../; make install;" > ${STAGING}/authsae.sh
chmod +x ${STAGING}/authsae.sh
do_stamp_cmd authsae.make sudo chroot ${STAGING} /authsae.sh
mkdir -p ${STAGING}/usr/local/share/authsae/ || exit 1
do_stamp_cmd authsae.files cp -r ${DISTRO11S_SRC}/authsae/config ${STAGING}/usr/local/share/authsae/

sudo umount ${DISTRO11S_SRC}
rm -f ${STAGING}/authsae.sh
