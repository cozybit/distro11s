#! /bin/bash
source `dirname $0`/../../scripts/common.sh

root_check "This script creates tap interfaces"

IFNAME=`sudo tunctl -u $USER -b`

function die {
	sudo tunctl -d ${IFNAME}
	exit $1
}

sudo /sbin/ifconfig ${IFNAME} ${DISTRO11S_HOST_IP} up || die 1

KERNEL=${DISTRO11S_OUT}/qemu/bzImage
ROOTFS=${DISTRO11S_OUT}/qemu/rootfs.ext3
qemu-system-`uname -i` -kernel ${KERNEL} -hda ${ROOTFS} \
	-append "root=/dev/sda combined_mode=ide console=ttyS0" \
	-nographic -net nic,model=e1000 -net tap,ifname=${IFNAME},script=no

# qemu will block here until it is done.  When it returns, we'll eliminate the
# tap iface.
die 0
