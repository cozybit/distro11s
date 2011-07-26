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

sed 's/^\([1-6]:[1-6]*:respawn:\)\/sbin\/getty \(38400 tty[1-6]\)$/\1\/sbin\/agetty \-n \-l \/bin\/autologin \2/' \
	< ${STAGING}/etc/inittab > ${STAGING}/etc/inittab.new
sudo mv -f ${STAGING}/etc/inittab.new ${STAGING}/etc/inittab


# disable root password
sed 's/^root:\*:\(.*\)$/root::\1/' < ${STAGING}/etc/shadow >  ${STAGING}/etc/shadow.new
mv -f ${STAGING}/etc/shadow.new ${STAGING}/etc/shadow

echo "Setting up static ip"
# set up static IP address if necessary
if [ "${DISTRO11S_STATIC_IFACE}" != "" ]; then
	echo "$(cat <<EOF
auto ${DISTRO11S_STATIC_IFACE}
iface ${DISTRO11S_STATIC_IFACE} inet static
 address ${DISTRO11S_STATIC_IP}
 netmask ${DISTRO11S_STATIC_NM}
EOF
)" > ${STAGING}/etc/network/interfaces
	rm -f ${STAGING}/etc/udev/rules.d/70-persistent-net.rules
fi

# Set up the sshfs automount if specified
if [ "${DISTRO11S_SSHFS_AUTOMOUNT_PATH}" != "" -a \
	"${DISTRO11S_HOST_IP}" != ""  ]; then
	warn_user "This script installs an ssh key without a password on your dev machine!"
	AUTH_KEYS=/home/${DISTRO11S_SSHFS_AUTOMOUNT_USER}/.ssh/authorized_keys
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
		cat ${PUB_KEY} >> ${STAGING}/root/.ssh/authorized_keys || exit 1
	fi
	echo "sshfs -o allow_other,idmap=user,UserKnownHostsFile=/dev/null,StrictHostKeyChecking=no " \
		"${DISTRO11S_SSHFS_AUTOMOUNT_USER}@${DISTRO11S_HOST_IP}:${DISTRO11S_SSHFS_AUTOMOUNT_PATH} " \
		"/mnt" > ${STAGING}/etc/rc.local
fi

PUB_KEY=/home/${DISTRO11S_SSHFS_AUTOMOUNT_USER}/.ssh/id_rsa.pub
AUTH_KEYS=${STAGING}/root/.ssh/authorized_keys
if [ -e  ${PUB_KEY} ]; then
	if [ ! -e ${AUTH_KEYS} ]; then
		touch ${AUTH_KEYS}
	fi
	grep "`cat ${PUB_KEY}`" ${AUTH_KEYS} > /dev/null
	if [ "$?" != "0" ]; then
		cat ${PUB_KEY} >> ${AUTH_KEYS} || exit 1
	fi
fi

sudo chown -R root.root ${STAGING}/root
sudo chmod 700 ${STAGING}/root
sudo chmod 700 ${STAGING}/root/.ssh

touch ${STAMPS}/qemu-cleanups
