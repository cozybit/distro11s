#!/bin/bash

source `dirname $0`/common.sh

PACKAGE=all
DIR="/"
# HOSTNAME set by foreach.sh
# don't push to ourselves
[ $HOSTNAME != `hostname` ] && U=root@$HOSTNAME.local

function print_help {
	echo "$(cat <<EOF
push.sh: push distro11s to a deployed system using rsync

-h            print this help message

-u <user@host> User and Hostname (or IP address) of the device to push to.

-d <directory> Directory in your target staging to sync with the device,
		default is ${DIR}
-p <package_name> It will push only the files related to that package

EOF
)"
}

# translate long options to short
for arg
do
        delim=""
        case "$arg" in
                --help) args="${args}-h ";;
		--board) args="${args}";;
                --dir) args="${args}-d ";;
		--package) args="${args}-p ";;
                # pass through anything else
                *) [[ "${arg:0:1}" == "--" ]] || delim="\""
                args="${args}${delim}${arg}${delim} ";;
        esac
done
# reset the translated args
eval set -- $args

while getopts "hu:d:b:p:" opt; do
	case $opt in
		b)	BOARD=${OPTARG};;
		h)	print_help
			exit 0;;
		u)	U=${OPTARG};;
		d)	DIR=${OPTARG};;
		p)	PACKAGE=${OPTARG};;
		\?)	echo "Invalid option: -${OPTARG}" >&2
			exit 1;;
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
SRC=${STAGING}/${DIR}/
DEST=${U}:${DIR}

if [ "${PACKAGE}" == "kernel" ]; then
	echo "About to push the kernel"
	sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK SSH_AGENT_PID=$SSH_AGENT_PID rsync -av ${SRC}boot/bzImage ${DEST}boot/bzImage || exit 1
	echo "About to push the modules"
	sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK SSH_AGENT_PID=$SSH_AGENT_PID rsync -av ${SRC}lib/modules/ ${DEST}lib/modules/ || exit 1

elif [ "${PACKAGE}" == "iw" -o "${PACKAGE}" == "authsae" -o "${PACKAGE}" == "libnl" -o "${PACKAGE}" == "meshkit" -o "${PACKAGE}" == "wmediumd" ]; then
	echo "About to push ${PACKAGE}: From ${SRC}usr/local/ to ${DEST}usr/local/"
	sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK SSH_AGENT_PID=$SSH_AGENT_PID rsync -av ${SRC}usr/local/ ${DEST}usr/local/ || exit 1

	if [ "${PACKAGE}" == "meshkit" ]; then
		sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK SSH_AGENT_PID=$SSH_AGENT_PID rsync -av ${SRC}etc/ ${DEST}etc/ || exit 1
	elif [ "${PACKAGE}" == "wmediumd" ]; then
		sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK SSH_AGENT_PID=$SSH_AGENT_PID rsync -av ${SRC}etc/wmediumd/ ${DEST}etc/wmediumd/ || exit 1
	fi

elif [ "${PACKAGE}" != "all" ]; then
	echo "Package not supported yet. Push all."
	exit 1
fi

if [ "${PACKAGE}" == "all" ]; then
	echo "About to push ${SRC} to ${DEST}"
	sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK SSH_AGENT_PID=$SSH_AGENT_PID rsync --exclude='*root/.ssh/*' --exclude='dev' --exclude='proc' --exclude='var/log' --exclude='mnt' --exclude='var/cache' -av ${SRC} ${DEST} || exit 1
fi
