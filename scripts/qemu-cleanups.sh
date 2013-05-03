#!/bin/bash
source `dirname $0`/common.sh

if [ -e ${STAMPS}/qemu-cleanups -a ! ${FORCE_BUILD} -eq 1 ]; then
	exit 0;
fi

# Launch a serial terminal at boot
CMD="T0:23:respawn:/sbin/getty -n -l /bin/autologin.sh -L ttyS0 38400 linux"
grep "${CMD}" ${STAGING}/etc/inittab > /dev/null
if [ ! $? -eq 0 ]; then
	echo ${CMD} >> ${STAGING}/etc/inittab
fi

# Automatically login as root
echo "$(cat <<EOF
#!/bin/sh
exec /bin/login -f root
EOF
)" > ${STAGING}/bin/autologin.sh
chmod +x ${STAGING}/bin/autologin.sh

sed 's/^\([1-6]:[1-6]*:respawn:\)\/sbin\/getty \(38400 tty[1-6]\)$/\1\/sbin\/agetty \-n \-l \/bin\/autologin\.sh \2/' \
	< ${STAGING}/etc/inittab > ${STAGING}/etc/inittab.new
sudo mv -f ${STAGING}/etc/inittab.new ${STAGING}/etc/inittab


# disable root password
sed 's/^root:\*:\(.*\)$/root::\1/' < ${STAGING}/etc/shadow >  ${STAGING}/etc/shadow.new
mv -f ${STAGING}/etc/shadow.new ${STAGING}/etc/shadow

sudo chmod 777 -R ${STAGING}/root/
# Set up the sshfs automount if specified
if [ "${DISTRO11S_SSHFS_AUTOMOUNT_PATH}" != "" -a \
	"${DISTRO11S_HOST_IP}" != ""  ]; then
	warn_user "This script installs an ssh key without a password on your dev machine!"
	AUTH_KEYS=`getent passwd $DISTRO11S_SSHFS_AUTOMOUNT_USER | cut -d: -f6`/.ssh/authorized_keys
	PUB_KEY=${STAGING}/root/.ssh/id_rsa.pub

	if [ -e ${PUB_KEY} ]; then
		# The ssh key has already been created, possibly from a previous
		# invocation of this script.  Don't clog up the developer's
		# authorized_keys file.
		grep "`cat ${PUB_KEY}`" ${AUTH_KEYS} > /dev/null
		if [ "$?" != "0" ]; then
			cat ${PUB_KEY} >> ${AUTH_KEYS} || exit 1
		fi
	else
		mkdir -p ${STAGING}/root/.ssh/
		yes | ssh-keygen -t rsa -N "" -f ${STAGING}/root/.ssh/id_rsa || exit 1
		cat ${PUB_KEY} >> ${AUTH_KEYS} || exit 1
	fi
	echo "sshfs -o allow_other,idmap=user,UserKnownHostsFile=/dev/null,StrictHostKeyChecking=no " \
		"${DISTRO11S_SSHFS_AUTOMOUNT_USER}@${DISTRO11S_HOST_IP}:${DISTRO11S_SSHFS_AUTOMOUNT_PATH} " \
		"/mnt" > ${STAGING}/etc/rc.local
fi

if [ "${DISTRO11S_SSH_PUB_KEY}" != "" -a -e "${DISTRO11S_SSH_PUB_KEY}" ]; then
	mkdir -p ${STAGING}/root/.ssh/
	AUTH_KEYS=${STAGING}/root/.ssh/authorized_keys
	if [ ! -e ${AUTH_KEYS} ]; then
		touch ${AUTH_KEYS}
	fi
	grep "`cat ${DISTRO11S_SSH_PUB_KEY}`" ${AUTH_KEYS} > /dev/null
	if [ "$?" != "0" ]; then
		cat ${DISTRO11S_SSH_PUB_KEY} >> ${AUTH_KEYS} || exit 1
	fi
fi
sudo chmod 644 -R ${STAGING}/root/
# Make sure the private key is only accessible by root
sudo chmod 600 ${STAGING}/root/.ssh/id_rsa
sudo chown -R root.root ${STAGING}/root

# set regulatory domain
echo "configuring regulatory domain: ${DISTRO11S_REGDOMAIN}"
echo "sed -i \"s/^REGDOMAIN=/REGDOMAIN=${DISTRO11S_REGDOMAIN}/\" ${STAGING}/etc/default/crda" | sudo sh
# CRDA debian package expects iw in /usr/sbin/ and /sbin/
sudo ln -fs ${STAGING}/usr/local/sbin/iw ${STAGING}/usr/sbin/iw
sudo ln -fs ${STAGING}/usr/local/sbin/iw ${STAGING}/sbin/iw

# Make tshark run capture as root
sudo sed -i -e 's/running_superuser/false/' ${STAGING}/usr/share/wireshark/init.lua

# Enable virtfs mounts
[ -z "$DISTRO11S_VIRTFS_MOUNT_DST" ] && DISTRO11S_VIRTFS_MOUNT_DST="/home"
echo "
misc $DISTRO11S_VIRTFS_MOUNT_DST 9p	trans=virtio,version=9p2000.L 0	0
modules /lib/modules 9p trans=virtio,version=9p2000.L 0 0
" > ${STAGING}/etc/fstab

touch ${STAMPS}/qemu-cleanups
