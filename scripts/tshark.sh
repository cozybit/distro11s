#!/bin/bash

source `dirname $0`/common.sh

if [ ! -d $PWD/packages/tshark ]; then
	echo "No tshark package."
	exit 1
fi

if [ ! -e ${STAMPS}/tshark.stamp -o ${FORCE_BUILD} -eq 1 ]; then
	Q pushd $PWD/packages/tshark
	cp *.deb ${STAGING}/tmp/
	# install wireshark_common and have it fail...
	ARCH="i386"
	[ "`uname -m`" == "x86_64" ] && ARCH="amd64"

	sudo chroot ${STAGING} apt-get -y --force-yes update
	sudo chroot ${STAGING} dpkg -i --force overwrite /tmp/wireshark-common_1.9.0_${ARCH}.deb
	# now tell apt-get to install the missing dependencies
	sudo chroot ${STAGING} apt-get -f install
	sudo chroot ${STAGING} dpkg -i --force overwrite /tmp/tshark_1.9.0_${ARCH}.deb && touch ${STAMPS}/tshark.stamp
	sudo rm ${STAGING}/tmp/*.deb
fi
