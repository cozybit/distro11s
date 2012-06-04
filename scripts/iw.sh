#!/bin/bash

source `dirname $0`/common.sh

sudo mkdir ${STAGING}/src
sudo mount --bind ${DISTRO11S_SRC} ${STAGING}/src
#sudo chroot ${STAGING} apt-get update
#sudo chroot ${STAGING} apt-get -y install autoconf bison flex libtool

#Q pushd ${DISTRO11S_SRC}/iw || exit 1

echo "cd /src/iw; make clean; make \
	PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/ \
	PREFIX=/usr/local/ \
	V=1 install;" > ${STAGING}/iw.sh
chmod +x ${STAGING}/iw.sh
do_stamp_cmd iw.make sudo chroot ${STAGING} /iw.sh

sudo umount ${DISTRO11S_SRC}
rm -f ${STAGING}/iw.sh
