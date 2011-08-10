LOOPDEV=/dev/loop0
MNTPOINT=/mnt/qemu-rootfs
IMGFILE=${PWD}/out/qemu/rootfs.ext3

sudo killall qemu
sudo losetup $LOOPDEV || sudo losetup -s $LOOPDEV $IMGFILE
sudo mount -t ext3 $LOOPDEV $MNTPOINT
sudo chroot $MNTPOINT bash
sudo umount $MNTPOINT
