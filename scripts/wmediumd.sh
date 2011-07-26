#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/wmediumd || exit 1
export CFLAGS="${CFLAGS} -D_GNU_SOURCE"
export SUBDIRS="rawsocket wmediumd"
do_stamp_cmd wmediumd.make make
do_stamp_cmd wmediumd.install cp ./wmediumd/wmediumd ${STAGING}/usr/local/bin
