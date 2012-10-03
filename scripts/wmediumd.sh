#!/bin/bash

source `dirname $0`/common.sh

[ -d ${STAGING}/src ] || sudo mkdir ${STAGING}/src
sudo mount --bind ${DISTRO11S_SRC} ${STAGING}/src

echo "cd /src/wmediumd; export CFLAGS=\"${CFLAGS} -D_GNU_SOURCE\"; export LDFLAGS=\"-L ${STAGING}/usr/local/lib -L ${STAGING}/usr/lib\"; export SUBDIRS=\"rawsocket wmediumd\"; make clean; make -j ${DISTRO11S_JOBS};" > ${STAGING}/wmediumd.sh
chmod +x ${STAGING}/wmediumd.sh
do_stamp_cmd wmediumd.make sudo chroot ${STAGING} /wmediumd.sh
do_stamp_cmd wmediumd.install cp ${DISTRO11S_SRC}/wmediumd/wmediumd/wmediumd ${STAGING}/usr/local/bin
mkdir -p ${STAGING}/etc/wmediumd/
do_stamp_cmd wmediumd.install_etc cp ${DISTRO11S_SRC}/wmediumd/wmediumd/cfg-examples/* ${STAGING}/etc/wmediumd/

sudo umount ${DISTRO11S_SRC}
rm -f ${STAGING}/wmediumd.sh
