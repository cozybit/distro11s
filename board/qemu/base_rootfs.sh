source `dirname $0`/../../scripts/common.sh

if [ ! -e  ${STAMPS}/qemu.bootstrapped -o ${FORCE_BUILD} -eq 1 ]; then
	root_check "This script runs debootstrap in ${STAGING}"
	echo "Populating base rootfs with debian"
	sudo rm -rf ${STAGING}/*
	sudo debootstrap sid ${STAGING} http://ftp.debian.org/debian || exit 1
	sudo chmod -R a+w ${STAGING}/
	sudo chmod -R a+r ${STAGING}/
	sudo chmod a+x ${STAGING}/root
	sudo chmod a+x ${STAGING}/ldconfig
	touch ${STAMPS}/qemu.bootstrapped
fi

if [ ! -e ${STAMPS}/qemu.basepkgs -o ${FORCE_BUILD} -eq 1 ]; then
	echo "Adding base packages"
	sudo chroot ${STAGING} apt-get -y --force-yes install vim make gcc sshfs \
		tcpdump openssh-server rsync libconfig-dev psmisc || exit 1
	touch ${STAMPS}/qemu.basepkgs
	exit
fi
