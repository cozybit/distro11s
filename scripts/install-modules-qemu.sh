# Copyright © 2011 cozybit Inc.  All rights reserved.

#! /bin/bash

source `dirname $0`/common.sh

LOOPDEV=/dev/loop0
MNTPOINT=`sudo mktemp -d --tmpdir=/mnt`
IMGFILE=${DISTRO11S_OUT}/qemu/rootfs.ext3

root_check "This script mounts the loop interface and copies kernel modules to it"

QEMU_RUNNING=`ps aux | grep -c 'qemu/bzImage'`
[ "${TEST}" == "y" -a  ${QEMU_RUNNING} -gt 1 ] && { echo "qemu is running! Please, halt it."; exit 1; }

sudo losetup $LOOPDEV || sudo losetup -s $LOOPDEV $IMGFILE
sudo mount -t ext3 $LOOPDEV $MNTPOINT
cd ${DISTRO11S_SRC}/kernel 
sudo INSTALL_MOD_PATH=$MNTPOINT make modules_install
HEAD_SHA=`git log --oneline -n1 | awk '{print $1}'`
if [ "`ls ${MNTPOINT}/lib/modules | grep ${HEAD_SHA}`" != "" ]; then
	echo "Deleting old modules"
	ls -d ${MNTPOINT}/lib/modules/* | grep -v ${HEAD_SHA} | xargs sudo rm -Rf
	ls -d ${STAGING}/lib/modules/* | grep -v ${HEAD_SHA} | xargs sudo rm -Rf
else
	echo "WARNING: The modules installed on your QEMU targe don't match the HEAD SHA of your repository!"
fi
sudo umount $MNTPOINT
