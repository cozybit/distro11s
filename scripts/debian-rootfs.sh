source `dirname $0`/common.sh

if [ ! -e  ${STAMPS}/debian-rootfs.bootstrapped -o ${FORCE_BUILD} -eq 1 ]; then
	root_check "This script runs debootstrap in ${STAGING}"
	echo "Populating base rootfs with debian"
	sudo rm -rf ${STAGING}/*
	sudo debootstrap sid ${STAGING} http://ftp.debian.org/debian || exit 1
	sudo chmod -R a+w ${STAGING}/
	sudo chmod -R a+r ${STAGING}/
	sudo chmod a+x ${STAGING}/root
	sudo chmod a+x ${STAGING}/ldconfig
	touch ${STAMPS}/debian-rootfs.bootstrapped
fi

if [ ! -e ${STAMPS}/debian-rootfs.basepkgs -o ${FORCE_BUILD} -eq 1 ]; then
	echo "Adding base packages"
	sudo chroot ${STAGING} apt-get -y --force-yes install ${BOARD11S_PACKAGES} || exit 1
	touch ${STAMPS}/debian-rootfs.basepkgs
fi

cp ${DISTRO11S_CONF} ${STAGING}/etc/distro11s.conf || exit 1

if [ "${DISTRO11S_RELEASE_VERSION}" = "" ]; then
	echo "DEVELOPMENT VERSION" > ${STAGING}/etc/distro11s-versions
else
	echo "distro11s release ${DISTRO11S_RELEASE_VERSION}"
fi
