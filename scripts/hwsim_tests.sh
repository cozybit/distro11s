#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/hwsim_tests || exit 1
mkdir -p ${STAGING}/root/hwsim_tests/ || exit 1
cp -r * ${STAGING}/root/hwsim_tests/ || exit 1
exit 0
