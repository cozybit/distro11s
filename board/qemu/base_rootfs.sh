source `dirname $0`/../../scripts/common.sh

if [ ${USER} != root ]; then
	echo "WARNING: This script runs debootstrap as root.  Press ENTER to continue."
	read n
fi

if [ ! -e  ${STAMPS}/qemu.bootstrapped ]; then
	echo "Populating base rootfs with debian"
	rm -rf ${STAGING}/*
	# Here we blow away any other stamps.  The reason is that if we blow away
	# the entire staging directory, we have to rebuild everything.
	rm -rf ${STAMPS}/*
	sudo debootstrap sid ${STAGING} http://ftp.debian.org/debian || exit 1
	sudo chmod -R a+w ${STAGING}/
	sudo chmod a+r ${STAGING}/etc/shadow
	touch ${STAMPS}/qemu.bootstrapped
fi

if [ ! -e ${STAMPS}/qemu.basepkgs ]; then
	echo "Adding base packages"
	sudo chroot ${STAGING} apt-get -y --force-yes install vim make gcc sshfs tcpdump || exit 1
	touch ${STAMPS}/qemu.basepkgs
	exit
fi
