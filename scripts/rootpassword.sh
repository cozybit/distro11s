#!/bin/bash

source `dirname $0`/common.sh

if [ "${DISTRO11S_ROOT_PW}" = "" ]; then
	exit 0
fi

warn_user "This script changes the root pw in ${STAGING}/etc/passwd."
sudo chroot ${STAGING} /bin/bash -c 'echo -e "'${DISTRO11S_ROOT_PW}'\n'${DISTRO11S_ROOT_PW}'\n" | passwd' || exit 1
