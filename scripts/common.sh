# Run a command quietly
function Q {
	$* > /dev/null
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

# fetch ${VCS} ${NAME} ${URL} ${BRANCH} ${TAG}
function fetch {
	DEST=${DISTRO11S_SRC}/${NAME}
	if [ ${1} = "git" ]; then
		GIT="git clone"
		if [ "${DISTRO11S_GIT_REFERENCE}" != "" -a -e ${DISTRO11S_GIT_REFERENCE}/${2} ]; then
			GIT="${GIT} --reference ${DISTRO11S_GIT_REFERENCE}/${2}"
		fi
		echo "${GIT}"
		if [ "${4}" = "" ]; then
			${GIT} ${3} ${DEST}
		else
			${GIT} ${3} -b ${4} ${DEST}
		fi
		if [ "${5}" != "" ] ; then
			pushd .
			cd ${DEST}
			git reset --hard ${5}
			popd
		fi
	elif [ ${1} = "svn" ]; then
		git svn clone ${3} ${DEST}
		#TODO: implement git reset --hard ${TAG} for git-svn
	else
		echo "Unsupported version control system ${1}"
		return 1
	fi
}

# update ${VCS} ${DIR} ${NAME} ${TAG}
function update {
	if [ ${1} = "git" ]; then
		Q pushd ${2}
		CURR_HEAD=`git log --oneline -n1 | awk '{print $1}'`
		[ "${4}" == "" ] && git pull --rebase
		NEW_HEAD=`git log --oneline -n1 | awk '{print $1}'`
	elif [ ${1} = "svn" ]; then
		Q pushd ${2}
		CURR_HEAD=`git log --oneline -n1 | awk '{print $1}'`
		[ "${4}" == "" ] && git svn rebase
		NEW_HEAD=`git log --oneline -n1 | awk '{print $1}'`
	else
		echo "Unsupported version control system ${1}"
		return 1
	fi

	if [ "${CURR_HEAD}" != "${NEW_HEAD}" ]; then
		# we had updates, clear the stamps, ignore missing
		Q "rm ${TOP}/out/${DISTRO11S_BOARD}/stamps/${3}*" || continue
	fi
}

# parse a pkglist line and set the relevant variables
function parse_pkg {
	export NAME=`echo ${*} | cut -d ';' -f 1`
	export VCS=`echo ${*} | cut -d ';' -f 2`
	export URL=`echo ${*} | cut -d ';' -f 3`
	export BRANCH=`echo ${*} | cut -d ';' -f 4`
	export TAG=`echo ${*} | cut -d ';' -f 5`
	export SRCDIR=${DISTRO11S_SRC}/${NAME}
	if [ "${NAME}" = "" ]; then
		echo "Need a package name!"; exit
	fi
}

# do a command if the specified stamp file $1 does not exist.
function do_stamp_cmd {
	STAMPFILE=${STAMPS}/${1}
	shift 1
	if [ ! -e ${STAMPFILE} -o ${FORCE_BUILD} -eq 1 ]; then
		eval "$*" || exit 1
		touch ${STAMPFILE}
	fi
}

function warn_user {
	if [ "${MSG}" = "" ]; then
		MSG="Proceed? [Yn]"
	fi
	echo ${*}
	while true; do
		read -p "${MSG}" yn
		case ${yn} in
			[Yy]* )
				break;;
			"" )
				break;;
			[Nn]* )
				exit 1;;
			* )
				echo "Please answer yes or no."
				;;
		esac
	done
}

function root_check {
	if [ ${USER} != root ]; then
		MSG="Use sudo? [Yn]"
		warn_user ${*}
		MSG=""
	fi
}

function pkg_version {
	if [ ${1} = "git" ]; then
		Q pushd ${2}
		git log | head -1 | awk '{print $2}'
	elif [ ${1} = "svn" ]; then
		Q pushd ${2}
		git svn log 2> /dev/null | head -2 | tail -1 | awk '{print $1}'
	else
		return 1
	fi
}

function add_text {
        _TXT=${1}
        _FILE=${2}
	_CHECK=`sudo grep "${_TXT}" ${_FILE}`
        [ "${_CHECK}" == "" ] && echo -e "echo \"${_TXT}\" >> ${_FILE}" | sudo sh
}

# Now perform all of the common setup steps and variables used by just about
# every script
set_top || exit 1

# Allow user to override configuration file in environment
if [ "${DISTRO11S_CONF}" = "" ]; then
	DISTRO11S_CONF=${TOP}/distro11s.conf
fi

# source the config variables
if [ -e ${DISTRO11S_CONF} ]; then
	source ${DISTRO11S_CONF}
else
	echo "Specified config file ${DISTRO11S_CONF} does not exist"
	exit 1
fi

# validate configuration
if [ "${DISTRO11S_SRC}" = "" ]; then
	echo "No DISTRO11S_SRC directory specified"
	exit 1;
fi

if [ "${DISTRO11S_OUT}" = "" ]; then
	echo "No DISTRO11S_OUT directory specified"
	exit 1;
fi

if [ "${DISTRO11S_BOARD}" = "" ]; then
	echo "No DISTRO11S_BOARD specified"
	exit 1;
fi

# set up some internal variables and directories
BOARDCONF=${TOP}/board/${DISTRO11S_BOARD}/${DISTRO11S_BOARD}.conf
if [ ! -e ${BOARDCONF} ]; then
	echo "Board ${DISTRO11S_BOARD} has no configuration (${BOARDCONF})"
	exit 1
fi
source ${BOARDCONF}

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

# Set some common variables
export PKG_CONFIG_PATH=${STAGING}/usr/share/pkgconfig:${STAGING}/usr/local/lib/pkgconfig
export CFLAGS="-I${STAGING}/usr/include -I${STAGING}/usr/local/include -I${DISTRO11S_SRC}/src/kernel/include"
export LDFLAGS="-L${STAGING}/lib -L${STAGING}/usr/lib -L${STAGING}/usr/local/lib"

if [ "${FORCE_BUILD}" = "" ]; then
	FORCE_BUILD=0
fi
