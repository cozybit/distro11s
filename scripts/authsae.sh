#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/authsae || exit 1
export CFLAGS="${CFLAGS} -D_GNU_SOURCE"
do_stamp_cmd authsae.make PREFIX=${STAGING}/usr/local make -C linux install
