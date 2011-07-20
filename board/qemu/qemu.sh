#! /bin/bash
source `dirname $0`/../../scripts/common.sh

root_check "This script creates tap interfaces"

IFNAME=`sudo tunctl -u $USER -b`

function die {
	sudo tunctl -d ${IFNAME}
	sudo /usr/sbin/brctl delbr br0
	exit $1
}

switch=$(/sbin/ip route list | awk '/^default / { print $5 }')
sudo /sbin/ifconfig ${IFNAME} 192.168.55.1 up || die 1
sudo /usr/sbin/brctl addbr br0 || die 1
sudo /usr/sbin/brctl addif br0 ${switch} || die 1

KERNEL=${DISTRO11S_OUT}/qemu/bzImage
ROOTFS=${DISTRO11S_OUT}/qemu/rootfs.ext3
qemu-system-`uname -i` -kernel ${KERNEL} -hda ${ROOTFS} \
	-append "root=/dev/sda combined_mode=ide console=ttyS0" \
	-nographic -net nic,model=e1000 -net tap,ifname=${IFNAME},script=no

# qemu will block here until it is done.  When it returns, we'll eliminate the
# tap iface.
die 0
