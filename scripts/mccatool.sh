#!/bin/bash

source `dirname $0`/common.sh

# this utility is checked into and only relevant to the mcca kernel
[ -d ${DISTRO11S_SRC}/kernel/mcca_utils ] || exit

[ -d ${STAGING}/src ] || sudo mkdir ${STAGING}/src
sudo mount --bind ${DISTRO11S_SRC} ${STAGING}/src

echo "cd /src/kernel/mcca_utils/mccatool; make;" > ${STAGING}/mccatool.sh
chmod +x ${STAGING}/mccatool.sh
do_stamp_cmd mccatool.make sudo chroot ${STAGING} /mccatool.sh

do_stamp_cmd mccatool.files cp -r ${DISTRO11S_SRC}/kernel/mcca_utils/mccatool/mccatool ${STAGING}/usr/local/bin/

sudo umount ${DISTRO11S_SRC}
rm -f ${STAGING}/mccatool.sh
