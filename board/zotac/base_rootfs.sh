source `dirname $0`/../../scripts/common.sh

if [ ! -e  ${STAMPS}/zotac.bootstrapped ]; then
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
	touch ${STAMPS}/zotac.bootstrapped
fi

if [ ! -e ${STAMPS}/zotac.basepkgs ]; then
	echo "Adding base packages"
	sudo chroot ${STAGING} apt-get -y --force-yes install vim make gcc sshfs tcpdump avahi-daemon avahi-discover libnss-mdns sudo wireless-tools || exit 1
	touch ${STAMPS}/zotac.basepkgs
	exit
fi
