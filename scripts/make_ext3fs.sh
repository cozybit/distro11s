source `dirname $0`/common.sh

if [ -e ${STAMPS}/make_ext3fs -a ! ${FORCE_BUILD} -eq 1 ]; then
	exit 0;
fi

function die {
	sudo losetup -d ${LOOPDEV}
	sudo umount /mnt
	exit $1
}

root_check "This script mounts drives and makes file systems."
IMAGE=${DISTRO11S_OUT}/${DISTRO11S_BOARD}/rootfs.ext3
SIZE=`sudo du -s -B 1k ${STAGING} | awk '{print $1}'`
SIZE=$((${SIZE}*140/100))
echo "Creating ${SIZE}kB ext3 file system image"
dd if=/dev/zero of=${IMAGE} bs=1k count=${SIZE} || exit 1
NUM=0
SUCCESS=0
for LOOPDEV in `ls /dev/loop*`; do
	echo "Trying loop device ${LOOPDEV}"
	sudo losetup ${LOOPDEV} ${IMAGE}
	R=${?}
	if [ "${R}" = "0" ]; then
		SUCCESS=1
		break;
	else
		continue
	fi
done
if [ ${SUCCESS} -eq 0 ]; then
	echo "Failed to set up loop device"
	exit 1
fi
sudo mkfs -t ext3 -m 1 -v ${LOOPDEV} || die 1
sudo mount -o loop ${IMAGE} /mnt || die 1
echo "Copying rootfs from ${STAGING}.  This may take a while...."
sudo cp -ra ${STAGING}/* /mnt || die 1
touch ${STAMPS}/make_ext3fs
die 0
