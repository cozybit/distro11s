#! /bin/bash

. scripts/common.sh

LOOPDEV=/dev/loop0
MNTPOINT=/mnt/qemu-rootfs
IMGFILE=${PWD}/out/qemu/rootfs.ext3

root_check "This script mounts the loop interface and copies kernel modules to it"
sudo killall qemu
sudo killall qemu-system-x86_64
sudo losetup $LOOPDEV || sudo losetup -s $LOOPDEV $IMGFILE
sudo mount -t ext3 $LOOPDEV $MNTPOINT
pushd src/kernel 
sudo INSTALL_MOD_PATH=$MNTPOINT make modules_install
popd
# Also copy the kernel to the place where qemu.sh expects it
sudo cp ${PWD}/src/kernel/arch/x86/boot/bzImage ${PWD}/out/qemu
sudo umount $MNTPOINT
