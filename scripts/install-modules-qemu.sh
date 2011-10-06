#! /bin/bash

. scripts/common.sh

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
sudo umount $MNTPOINT
