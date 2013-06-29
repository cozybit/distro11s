#!/bin/bash

source `dirname $0`/common.sh

kernel_src=${DISTRO11S_SRC}/kernel

COMPAT_SRC=${DISTRO11S_SRC}/compat-drivers-releases
cd ${COMPAT_SRC}

# clean to rebuild
make clean

cp ${COMPAT_SRC}/drivers/net/wireless/Makefile ${COMPAT_SRC}/drivers/net/wireless/Makefile.old

# only want to build and apply to hwim
cat ${COMPAT_SRC}/drivers/net/wireless/Makefile.old | grep HWSIM > ${COMPAT_SRC}/drivers/net/wireless/Makefile

# build
do_stamp_cmd compat.make KLIB_BUILD=$kernel_src KLIB=$kernel_src
# install
echo 'installing compat drivers'
sudo make KLIB_BUILD=$kernel_src KLIB=$kernel_src KMODPATH_ARG="INSTALL_MOD_PATH=${STAGING}" install-modules

git checkout ${COMPAT_SRC}/drivers/net/wireless/Makefile

echo 'done installing compat drivers'
