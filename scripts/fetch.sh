#!/bin/bash

source `dirname $0`/common.sh

function print_help {
	echo "$(cat <<EOF
fetch.sh: fetch distro11s source code

Fetch each source package as specified in the specified board's pkglist.  Then
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
while read l; do
	parse_pkg $l
	if [ -e  ${SRCDIR} ]; then
		echo "UPDATING: ${SRCDIR}"
		update ${VCS} ${SRCDIR} ${URL} ${BRANCH} || exit 1
	else
		echo "FETCHING: ${NAME}"
		fetch ${VCS} ${SRCDIR} ${URL} ${BRANCH} || exit 1
	fi
done < ${PKGLIST}
echo "all distro11s source packages fetched"
