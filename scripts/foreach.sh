#!/bin/bash

source `dirname $0`/common.sh

if [ "${DISTRO11S_NUM_NODES}" = "" ]; then
	echo "Cannot do foreach unless DISTRO11S_NUM_NODES is configured"
	exit 1
fi

for n in `seq 0 $((${DISTRO11S_NUM_NODES} - 1))`; do
	SUFFIX=$((`echo ${DISTRO11S_STATIC_IP} | cut -d '.' -f 4` + ${n}))
	export IP=`echo ${DISTRO11S_STATIC_IP} | cut -d '.' -f 1-3`".${SUFFIX}"
	export HOSTNAME=${DISTRO11S_HOSTNAME}-${n}
	export HOSTNUM=${n}
	eval $*
done
