#!/bin/bash
# Copyright (c) 2013 cozybit Inc.
#
# All rights reserved
#

# Pretty simple package.  Allow a local and board-specific overlay file system.
# This allows us to cleanly add and alter files such as /etc/init.d/* with our
# own specific stuff
source `dirname $0`/common.sh

do_stamp_cmd overlay.distro11s cp -r ${TOP}/overlay/* ${STAGING}

if [ -d ${TOP}/board/${DISTRO11S_BOARD}/overlay ]; then
	do_stamp_cmd overlay.board sudo cp -r ${TOP}/board/${DISTRO11S_BOARD}/overlay/* ${STAGING}
fi
