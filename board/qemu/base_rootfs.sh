source `dirname $0`/../../scripts/common.sh

if [ ! -e  ${STAMPS}/qemu.bootstrapped ]; then
	root_check "This script runs debootstrap"
	echo "Populating base rootfs with debian"
	rm -rf ${STAGING}/*
	# Here we blow away any other stamps.  The reason is that if we blow away
	# the entire staging directory, we have to rebuild everything.
	rm -rf ${STAMPS}/*
	sudo debootstrap sid ${STAGING} http://ftp.debian.org/debian || exit 1
	sudo chmod -R a+w ${STAGING}/
	sudo chmod -R a+r ${STAGING}/
	sudo chmod a+x ${STAGING}/root
	sudo chmod a+x ${STAGING}/ldconfig
	touch ${STAMPS}/qemu.bootstrapped
fi

if [ ! -e ${STAMPS}/qemu.basepkgs ]; then
	echo "Adding base packages"
	sudo chroot ${STAGING} apt-get -y --force-yes install vim make gcc sshfs \
		tcpdump openssh-server rsync || exit 1
	touch ${STAMPS}/qemu.basepkgs
	exit
fi
