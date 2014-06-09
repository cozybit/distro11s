#!/bin/bash
# Copyright (c) 2013 cozybit Inc.
#
# All rights reserved
#

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/hwsim_tests || exit 1
mkdir -p ${STAGING}/usr/local/share/hwsim_tests/ || exit 1
cp -r * ${STAGING}/usr/local/share/hwsim_tests/ || exit 1
exit 0
