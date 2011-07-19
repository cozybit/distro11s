#!/bin/bash

source `dirname $0`/common.sh

function print_help {
	echo "$(cat <<EOF
build.sh: build distro11s for the specified board

-h            print this help message

EOF
)"
}

while getopts "h" opt; do
  case $opt in
    h)
      print_help
	  exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
	  exit 1
      ;;
  esac
done

# prepare the base rootfs
ROOTFS=${TOP}/board/${DISTRO11S_BOARD}/base_rootfs.sh
if [ -e ${ROOTFS} ]; then
	${ROOTFS} || exit $?
else
	echo "WARNING: No base rootfs script.  Proceeding anyway."
fi

# Go package by package and build
while read l; do
	parse_pkg $l
	if [ "${URL}" != "" -a ! -e  ${SRCDIR} ]; then
		echo "Expected package ${NAME} in ${SRCDIR}.  Consider running fetch.sh"
		exit 1
	fi
	S=${TOP}/scripts/${NAME}.sh
	if [ ! -e ${S} ]; then
		echo "Build script for package ${NAME} does not exist: ${S}."
		exit 1
	fi

	# Set some common variables
	export CFLAGS="-I${STAGING}/usr/include -I${STAGING}/usr/local/include"
	export LDFLAGS="-L${STAGING}/lib -L${STAGING}/usr/lib -L${STAGING}/usr/local/lib"
	echo "Building ${NAME}"
	$S || exit $?
done < ${PKGLIST}
echo "distro11s build complete."
