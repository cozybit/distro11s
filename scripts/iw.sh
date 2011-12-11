#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/iw || exit 1

do_stamp_cmd iw.make "make clean; make \
	PKG_CONFIG_PATH=${STAGING}/usr/local/lib/pkgconfig/ \
	PREFIX=${STAGING}/usr/local/ \
	V=1 install;"
