#!/bin/bash
# Copyright (c) 2013 cozybit Inc.
#
# All rights reserved
#

source `dirname $0`/common.sh

[ -d ${STAGING}/src ] || sudo mkdir ${STAGING}/src
sudo mount --bind ${DISTRO11S_SRC} ${STAGING}/src

echo "cd /src/iw; make clean; make \
	PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/ \
	PREFIX=/usr/local/ \
	V=1 install;" > ${STAGING}/iw.sh
chmod +x ${STAGING}/iw.sh
do_stamp_cmd iw.make sudo chroot ${STAGING} /iw.sh

sudo umount ${STAGING}/src
rm -f ${STAGING}/iw.sh
