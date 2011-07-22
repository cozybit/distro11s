#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/iw || exit 1
do_stamp_cmd iw.make PREFIX=${STAGING}/usr/local make install
