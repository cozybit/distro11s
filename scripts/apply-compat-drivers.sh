#!/bin/bash

source `dirname $0`/common.sh

kernel_src=${DISTRO11S_SRC}/kernel

cd ${DISTRO11S_SRC}/compat-drivers-releases

# clean to rebuild
make clean

# only want to build and apply to hwim
cat drivers/net/wireless/Makefile | grep HWSIM > drivers/net/wireless/Makefile

# build
do_stamp_cmd compat.make KLIB_BUILD=$kernel_src KLIB=$kernel_src
# install
echo 'installing compat drivers'
sudo make KLIB_BUILD=$kernel_src KLIB=$kernel_src KMODPATH_ARG="INSTALL_MOD_PATH=${STAGING}" install-modules

echo 'done installing compat drivers'
