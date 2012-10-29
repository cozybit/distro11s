#!/bin/bash

source `dirname $0`/common.sh

[ -d ${STAGING}/src ] || sudo mkdir ${STAGING}/src
sudo mount --bind ${DISTRO11S_SRC} ${STAGING}/src

echo "cd /src/trace-cmd; make trace-cmd;" > ${STAGING}/trace-cmd.sh
chmod +x ${STAGING}/trace-cmd.sh
do_stamp_cmd trace-cmd.make sudo chroot ${STAGING} /trace-cmd.sh

do_stamp_cmd trace-cmd.files cp -r ${DISTRO11S_SRC}/trace-cmd/trace-cmd ${STAGING}/usr/local/bin/

sudo umount ${DISTRO11S_SRC}
rm -f ${STAGING}/trace-cmd.sh
