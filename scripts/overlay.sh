#!/bin/bash

# Pretty simple package.  Allow a board-specific overlay file system.  This
# allows us to cleanly add and alter files such as /etc/init.d/* with our own
# board specific stuff
source `dirname $0`/common.sh

if [ -d ${TOP}/board/${DISTRO11S_BOARD}/overlay ]; then
	do_stamp_cmd overlay cp -r ${TOP}/board/${DISTRO11S_BOARD}/overlay/* ${STAGING}
fi
