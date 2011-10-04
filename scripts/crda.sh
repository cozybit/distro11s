
#!/bin/bash

source `dirname $0`/common.sh

Q pushd ${DISTRO11S_SRC}/crda || exit 1

do_stamp_cmd crda.make "make clean; PREFIX=${STAGING}/usr/local make -j ${DISTRO11S_JOBS};"
do_stamp_cmd crda.install DESTDIR=${STAGING} make install && cp hostapd.conf ${STAGING}/etc/
