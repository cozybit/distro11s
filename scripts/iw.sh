#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/iw || exit 1

do_stamp_cmd iw.make make \
	PKG_CONFIG_LIBDIR=${STAGING}/usr/local/lib/pkgconfig/ \
	PREFIX=${STAGING}/usr/local/ \
	V=1 install
