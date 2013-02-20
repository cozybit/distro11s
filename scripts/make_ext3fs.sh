source `dirname $0`/common.sh

if [ -e ${STAMPS}/make_ext3fs -a ! ${FORCE_BUILD} -eq 1 ]; then
	exit 0;
fi

function die {
	sudo umount ${MNTPOINT}
	sudo losetup -d ${LOOPDEV}
	exit $1
}

root_check "This script mounts drives and makes file systems."
IMAGE=${DISTRO11S_OUT}/${DISTRO11S_BOARD}/rootfs.ext3
sudo cat $STAGING/etc/distro11s-versions.d/* > $STAGING/etc/distro11s-versions
SIZE=`sudo du -s -B 1k ${STAGING} | awk '{print $1}'`
# add another 20% for extra modules, programs, etc.
SIZE=`echo "($SIZE * 120 / 100) + $SIZE" | bc`
echo "Creating ${SIZE}kB ext3 file system image"
dd if=/dev/zero of=${IMAGE} bs=1k count=${SIZE} || exit 1
LOOPDEV=`sudo losetup --show --find ${IMAGE}`
MNTPOINT=`sudo mktemp -d --tmpdir=/mnt`
sudo mkfs -t ext3 -m 1 -v ${LOOPDEV} || die 1
sudo mount ${LOOPDEV} ${MNTPOINT} || die 1
echo "Copying rootfs from ${STAGING} to ${MNTPOINT}.  This may take a while...."
sudo cp -ra ${STAGING}/* ${MNTPOINT} || die 1
touch ${STAMPS}/make_ext3fs
die 0
