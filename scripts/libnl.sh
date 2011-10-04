#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/libnl || exit 1
do_stamp_cmd libnl.autogen ./autogen.sh
do_stamp_cmd libnl.configure ./configure --prefix=${STAGING}/usr/local
do_stamp_cmd libnl.make make clean && make -j ${DISTRO11S_JOBS}
do_stamp_cmd libnl.install make install
