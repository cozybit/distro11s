#!/bin/bash

source `dirname $0`/common.sh

function print_help {
	echo "$(cat <<EOF
fetch.sh: fetch distro11s source code

Fetch each source package as specified in the specified board\'s pkglist.  Then
source trees will end up in the specified src dir.  If a src package already
exists, it is updated.

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

# Fetch each of the packages in the package list
for p in `cat ${PKGLIST}`; do
	parse_pkg ${p}
	if [ "${VCS}" = "" ]; then
		# If a VCS was not specified, we just move along.  This allows us to
		# have pseudo packages that have an install script but no src code.
		continue
	fi

	if [ -e  ${SRCDIR} ]; then
		echo "UPDATING: ${SRCDIR}"
		update_pkg || exit 1
	else
		echo "FETCHING: ${NAME}"
		fetch_pkg || exit 1
		if [ -d ${TOP}/patches/${NAME} ]; then
			Q pushd ${SRCDIR}
			git am ${TOP}/patches/${NAME}/* || exit 1
			Q popd
		fi
		if [ -d ${TOP}/board/${DISTRO11S_BOARD}/patches/${NAME} ]; then
			Q pushd ${SRCDIR}
			git am ${TOP}/board/${DISTRO11S_BOARD}/patches/${NAME}/* || exit 1
			Q popd
		fi
		# make sure package rebuilds if we blew away src dir to start from scratch
		Q "rm -f ${TOP}/out/${DISTRO11S_BOARD}/stamps/${NAME}*"
	fi
done
echo "all distro11s source packages fetched"
