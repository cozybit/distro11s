# Copyright © 2011 cozybit Inc.  All rights reserved.

#! /bin/bash
source `dirname $0`/../../scripts/common.sh

[ "${DISTRO11S_BOARD}" != "qemu" ] && \
	{ echo "The used config file is not valid for a qemu target. Change it or use \"export DISTRO11S_CONFIG=/path/to/qemu/config/\""; exit 1; }

root_check "This script creates tap interfaces"

IFNAME=`sudo tunctl -u ${USER} -b`

function die {
	sudo tunctl -d ${IFNAME}
	exit $1
}

sudo /sbin/ifconfig ${IFNAME} ${DISTRO11S_HOST_IP} up || die 1

KERNEL=${DISTRO11S_OUT}/qemu/bzImage
ROOTFS=${DISTRO11S_OUT}/qemu/rootfs.ext3


QEMU=qemu-system-`uname -m`
CHECK=`which ${QEMU}`
if [ "${CHECK}" == "" ]; then
    QEMU=qemu
fi

${QEMU} -kernel ${KERNEL} -hda ${ROOTFS} \
	-append "root=/dev/sda combined_mode=ide console=ttyS0" \
	-nographic -net nic,model=e1000 -net tap,ifname=${IFNAME},script=no \
	-gdb tcp::1234 \
	-enable-kvm -smp 2

# qemu will block here until it is done.  When it returns, we'll eliminate the
# tap iface.
die 0
