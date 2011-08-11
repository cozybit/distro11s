#!/bin/bash

source `dirname $0`/common.sh

DESTINATION="/"
# HOSTNAME set by foreach.sh
# don't push to ourselves
[ $HOSTNAME != `hostname` ] && U=root@$HOSTNAME.local

function print_help {
	echo "$(cat <<EOF
push.sh: push distro11s to a deployed system using rsync

-h            print this help message

-u <user@host> User and Hostname (or IP address) of the device to push to.

-d <destination> Destination directory on the device (default is
                 ${DESTINATION})

EOF
)"
}

while getopts "hu:d:b:" opt; do
	case $opt in
		h)
			print_help
			exit 0
			;;
		u)
			U=${OPTARG}
			;;
		d)
			DESTINATION=${OPTARG}
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
	esac
done

# Validate parameters
if [ "${BOARD}" = "" ]; then
	BOARD=${DISTRO11S_BOARD}
fi

if [ "${U}" = "" ]; then
	echo "Who shall I push to?  -u option is required."
	exit 1
fi

if [[ "${U}" == *@`hostname`* ]]; then
	echo "Pushing to yourself, don't think you want to do this!"
	exit 1
fi

# NB: trailing slash is important!
SRC=${STAGING}/
DEST=${U}:${DESTINATION}
echo "About to push ${SRC} to ${DEST}"
sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK SSH_AGENT_PID=$SSH_AGENT_PID rsync --exclude='*root/.ssh/*' -av ${SRC} ${DEST} || exit 1
