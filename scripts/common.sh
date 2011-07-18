# Run a command quietly
function Q {
	$* > /dev/null 2>&1
}

# set the TOP variable to the top of the distro11s source tree.  Assume that $0
# came from the scripts directory.
function set_top {
	COUNT=5
	while [ ${COUNT} -gt 0 ]; do
		if [ -d scripts -a -e README -a -d board -a -e scripts/fetch.sh ]; then
			# Okay.  We're convinced this is the top.
			TOP=${PWD}
			return 0
		fi
		COUNT=$(($COUNT - 1))
		cd ..
	done
	echo "Failed to find top directory."
	return 1
}

# fetch ${VCS} ${DEST} ${URL} ${BRANCH}
function fetch {
	if [ ${1} = "git" ]; then
		if [ "${4}" = "" ]; then
			git clone ${3} ${2}
		else
			git clone ${3} -b ${4} ${2}
		fi
	else
		echo "Unsupported version control system ${1}"
		return 1
	fi
}

# update ${VCS} ${DIR}
function update {
	if [ ${1} = "git" ]; then
		Q pushd ${2}
		git pull --rebase
	else
		echo "Unsupported version control system ${1}"
		return 1
	fi
}

# parse a pkglist line and set the relevant variables
function parse_pkg {
	export NAME=`echo ${*} | cut -d ';' -f 1`
	export VCS=`echo ${*} | cut -d ';' -f 2`
	export URL=`echo ${*} | cut -d ';' -f 3`
	export BRANCH=`echo ${*} | cut -d ';' -f 4`
	export SRCDIR=${SRC}/${NAME}
}

# Now perform all of the common setup steps and variables used by just about
# every script
set_top || exit 1

# source the config variables
if [ -e ${TOP}/distro11s.conf ]; then
	source ${TOP}/distro11s.conf
fi

# validate configuration
if [ "${DISTRO11S_SRC}" = "" ]; then
	echo "No DISTRO11S_SRC directory specified"
	exit 1;
fi

if [ "${DISTRO11S_BOARD}" = "" ]; then
	echo "No DISTRO11S_BOARD specified"
	exit 1;
fi

# set up some internal variables and directories
PKGLIST=${TOP}/board/${DISTRO11S_BOARD}/pkglist
if [ ! -e ${PKGLIST} ]; then
	echo "Board ${DISTRO11S_BOARD} has no package list (${PKGLIST})"
	exit 1
fi

mkdir -p ${DISTRO11S_SRC}
STAGING=${DISTRO11S_OUT}/${DISTRO11S_BOARD}/staging
mkdir -p ${STAGING}
STAMPS=${DISTRO11S_OUT}/${DISTRO11S_BOARD}/stamps
mkdir -p ${STAMPS}
