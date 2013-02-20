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
	mkdir -p ${STAGING}/etc/distro11s-versions.d
	echo "Adding source URIs to sources.list"
	cat ${STAGING}/etc/apt/sources.list | sed -e 's/^deb/deb-src/' >> ${STAGING}/etc/apt/sources.list
	touch ${STAMPS}/debian-rootfs.bootstrapped
fi

echo "Updating package cache"
sudo chroot ${STAGING} apt-get update
echo "Install locales support"
sudo chroot ${STAGING} apt-get -y install locales
sudo chroot ${STAGING} sed -i -e "s/^#\s*\(.*$LANG\)/\1/" /etc/locale.gen
sudo chroot ${STAGING} locale-gen
echo "Updating base packages"
sudo chroot ${STAGING} apt-get -y upgrade
sudo chroot ${STAGING} apt-get -y --force-yes --no-install-recommends install ${BOARD11S_PACKAGES} || exit 1
sudo chroot ${STAGING} apt-get -y build-dep ${BOARD11S_BUILDDEP_PACKAGES} || exit 1

cp ${DISTRO11S_CONF} ${STAGING}/etc/distro11s.conf || exit 1

if [ "${DISTRO11S_RELEASE_VERSION}" = "" ]; then
	Q pushd ${TOP}
	echo "distro11s development " `git log | head -1 | awk '{print $2}'` > ${STAGING}/etc/distro11s-versions.d/distro11s
else
	echo "distro11s release ${DISTRO11S_RELEASE_VERSION}" > ${STAGING}/etc/distro11s-versions.d/distro11s
fi
