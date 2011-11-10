# Copyright © 2011 cozybit Inc.  All rights reserved.

#!/bin/bash

source `dirname $0`/common.sh

if [ "${DISTRO11S_NUM_NODES}" = "" ]; then
	echo "Cannot do foreach unless DISTRO11S_NUM_NODES is configured"
	exit 1
fi

if [ "${DISTRO11S_START_NODE}" = "" ]; then
	DISTRO11S_START_NODE=0
fi

if [ "${DISTRO11S_END_NODE}" = "" ]; then
	DISTRO11S_END_NODE=$((${DISTRO11S_NUM_NODES} - 1))
fi

for n in `seq ${DISTRO11S_START_NODE} ${DISTRO11S_END_NODE}`; do
	SUFFIX=$((`echo ${DISTRO11S_STATIC_IP} | cut -d '.' -f 4` + ${n}))
	export IP=`echo ${DISTRO11S_STATIC_IP} | cut -d '.' -f 1-3`".${SUFFIX}"
	export HOSTNAME=${DISTRO11S_HOSTNAME}-${n}
	export HOSTNUM=${n}
	eval $*
done
