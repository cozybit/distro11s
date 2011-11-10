# Copyright © 2011 cozybit Inc.  All rights reserved.

#!/bin/bash

source `dirname $0`/common.sh

if [ "${DISTRO11S_ROOT_PW}" = "" ]; then
    echo "Warning! The root password not set. Please, edit the disto11s.conf, and set it. Aborting..."
	exit 1
fi

warn_user "This script changes the root pw in ${STAGING}/etc/passwd."
sudo chroot ${STAGING} /bin/bash -c 'echo -e "'${DISTRO11S_ROOT_PW}'\n'${DISTRO11S_ROOT_PW}'\n" | passwd' || exit 1
