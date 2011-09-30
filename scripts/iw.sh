#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/iw || exit 1

# iw Makefile fixup
sed -i -e 's/libnl-3.0/libnl-3.1/' ${DISTRO11S_SRC}/iw/Makefile

do_stamp_cmd iw.make make \
	PKG_CONFIG_PATH=${STAGING}/usr/local/lib/pkgconfig/ \
	PREFIX=${STAGING}/usr/local/ \
	V=1 install
