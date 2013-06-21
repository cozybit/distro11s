#! /bin/bash
#
# if numerical argument is given, create a networked qemu instance
#
source `dirname $0`/../../scripts/common.sh

[ "${DISTRO11S_BOARD}" != "qemu" ] && \
	{ echo "The used config file is not valid for a qemu target. Change it or use \"export DISTRO11S_CONFIG=/path/to/qemu/config/\""; exit 1; }

IFNAME=`sudo tunctl -u ${USER} -b`

[ -n "$1" -a ! -n "${DISTRO11S_BRIDGE}" ] && { echo "Please define DISTRO11S_BRIDGE in distro11s.conf if you need networked qemu instances"; exit 1; }

function die {
	sudo tunctl -d ${IFNAME}

	[ ! -n "${DISTRO11S_BRIDGE}" ] && exit $1
	sudo ip link set ${DISTRO11S_BRIDGE} down
	# HACK: only delete bridge when instance 0 is brought down, which requires
	# that you halt qemu.sh 0 last
	[ "${IDX}" -eq 0 ] && sudo brctl delbr ${DISTRO11S_BRIDGE}
	exit $1
}

KERNEL=${DISTRO11S_OUT}/qemu/bzImage
ROOTFS=${DISTRO11S_OUT}/qemu/rootfs.ext3
IDX=0

# Create clone rootfs images if needed
if [ -n "$1" ]
then
	COW2_BASE=rootfs.cow2
	pushd ${DISTRO11S_OUT}/qemu;
	[ -f ${COW2_BASE} ] || qemu-img convert `basename ${ROOTFS}` -O qcow2 ${COW2_BASE}
	COW2_CLONE=${COW2_BASE%.cow2}-$1.cow2
	[ -f ${COW2_CLONE} ] || qemu-img create -b ${COW2_BASE} -f qcow2 ${COW2_CLONE}
	ROOTFS=${DISTRO11S_OUT}/qemu/${COW2_CLONE}
	popd
	IDX=$1
fi

# Create bridge
if [ -n "${DISTRO11S_BRIDGE}" ]
then
	# HACK: only create bridge for instance 0, which requires
	# that you launch qemu.sh 0 before any other
	[ ${IDX} -eq 0 ] && sudo brctl addbr ${DISTRO11S_BRIDGE}
	sudo brctl addif ${DISTRO11S_BRIDGE} ${IFNAME}
	sudo /sbin/ifconfig ${IFNAME} 0.0.0.0 || die 1
	sudo /sbin/ifconfig ${DISTRO11S_BRIDGE} ${DISTRO11S_HOST_IP} up || die 1
else
	sudo /sbin/ifconfig ${IFNAME} ${DISTRO11S_HOST_IP} up || die 1
fi



QEMU=qemu-system-`uname -m`
CHECK=`which ${QEMU}`
if [ "${CHECK}" == "" ]; then
    QEMU=qemu
fi

# virtfs rootfs
#	-append "root=root rw rootflags=rw,trans=virtio,version=9p2000.L rootfstype=9p combined_mode=ide console=ttyS0" \
#	-fsdev local,id=root,path=${STAGING},security_model=none \
#	-device virtio-9p-pci,fsdev=root,mount_tag=/dev/root \
[ -z "$DISTRO11S_VIRTFS_MOUNT_SRC" ] && DISTRO11S_VIRTFS_MOUNT_SRC="/home"
${QEMU} -nographic -kernel ${KERNEL} \
	-hda ${ROOTFS} \
	-append "root=/dev/sda combined_mode=ide console=ttyS0" \
	-fsdev local,id=modules,path=${STAGING}/lib/modules,security_model=mapped \
	-fsdev local,id=misc,path=${DISTRO11S_VIRTFS_MOUNT_SRC},security_model=mapped \
	-device virtio-9p-pci,fsdev=modules,mount_tag=modules \
	-device virtio-9p-pci,fsdev=misc,mount_tag=misc \
	-device e1000,netdev=lan0,mac=52:54:00:12:34:$((56 + IDX)) \
	-netdev tap,id=lan0,ifname=$IFNAME,script=no \
	-enable-kvm -smp 2 \
	-gdb tcp::$((1234 + IDX))

# To add a usb device to your qemu build:
# 1. Make sure you blacklist the module on your host (e.g add blacklist file on 
#    /etc/modprobe.d/blacklist-carl9170.conf that contains: blacklist carl9170).
# 2. Add the usb driver to your build
# 3. Claim ownership of the device by passing the following arguments to qemu:
#	- usb \
#	-device usb-ehci,id=ehci \
#	-device usb-host,vendorid=0x0cf3,productid=0x9271,bus=ehci.0 \
# (0cf3:9271 is for a tp-link wn721n (ath9k_htc))

# qemu will block here until it is done.  When it returns, we'll eliminate the
# tap iface.
die 0
