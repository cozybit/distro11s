#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/iw || exit 1

# iw Makefile fixup
sed -i -e 's/^LIBS += -lnl-genl$/LIBS += -lnl-genl-3/' ${DISTRO11S_SRC}/iw/Makefile

do_stamp_cmd iw.make make \
	PKG_CONFIG_LIBDIR=${STAGING}/usr/local/lib/pkgconfig \
	PREFIX=${STAGING}/usr/local \
	V=1 install
