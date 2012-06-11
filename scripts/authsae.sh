#!/bin/bash

source `dirname $0`/common.sh

sed -i -e 's/-lnl-3/-lnl/' ${DISTRO11S_SRC}/authsae/linux/Makefile
sed -i -e 's/-lnl-genl-3/-lnl-genl/' ${DISTRO11S_SRC}/authsae/linux/Makefile

sudo mkdir ${STAGING}/src
sudo mount --bind ${DISTRO11S_SRC} ${STAGING}/src

#Q pushd ${DISTRO11S_SRC}/authsae || exit 1

echo "cd /src/authsae; export CFLAGS=\"${CFLAGS} -D_GNU_SOURCE\"; make clean; PREFIX=/usr/local make -C linux install;" > ${STAGING}/authsae.sh
chmod +x ${STAGING}/authsae.sh
do_stamp_cmd authsae.make sudo chroot ${STAGING} /authsae.sh
mkdir -p ${STAGING}/usr/local/share/authsae/ || exit 1
do_stamp_cmd authsae.files cp -r ${DISTRO11S_SRC}/authsae/config ${STAGING}/usr/local/share/authsae/

sudo umount ${DISTRO11S_SRC}
rm -f ${STAGING}/authsae.sh
