#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/authsae || exit 1
export CFLAGS="${CFLAGS} -D_GNU_SOURCE"
do_stamp_cmd authsae.make make clean && PREFIX=${STAGING}/usr/local make -C linux install
mkdir -p ${STAGING}/usr/local/share/authsae/ || exit 1
do_stamp_cmd authsae.files cp -r ./config ${STAGING}/usr/local/share/authsae/
