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

function fetch_pkg {
	DEST=${DISTRO11S_SRC}/${NAME}
	if [ ${VCS} = "git" ]; then
		GIT="git clone"
		if [ "${DISTRO11S_GIT_REFERENCE}" != "" -a -e ${DISTRO11S_GIT_REFERENCE}/${NAME} ]; then
			GIT="${GIT} --reference ${DISTRO11S_GIT_REFERENCE}/${NAME}"
		fi
		echo "${GIT}"
		if [ "${BRANCH}" = "" ]; then
			${GIT} ${URL} ${DEST}
		else
			${GIT} ${URL} -b ${BRANCH} ${DEST}
		fi
		if [ "${TAG}" != "" ] ; then
			pushd .
			cd ${DEST}
			git reset --hard ${TAG}
			popd
		fi
	else
		echo "Unsupported version control system ${VCS}"
		return 1
	fi
}

function update_pkg {
	if [ ${VCS} = "git" ]; then
		Q pushd ${SRCDIR}
		CURR_HEAD=`git log --oneline -n1 | awk '{print $1}'`
		if [ "${BRANCH}" != `git rev-parse --abbrev-ref HEAD` ]; then
			if [ ${FORCE_BUILD} -eq 1 ]; then
				git remote rm origin
				git remote add origin ${URL}
				git remote update origin
				if [ "${BRANCH}" = "" ]; then
					git branch -D ${BRANCH}
					git checkout -b ${BRANCH} origin/${BRANCH}
				else
					git branch -D master
					git checkout -b ${BRANCH} origin/master
				fi
			else
				echo "WARNING: skipping update of ${NAME} in ${SRCDIR}"
				echo "	${SRCDIR} not presently on ${BRANCH}"
				echo "	use FORCE_BUILD=1 to override or cleanup manually"
			fi
		elif [ "${TAG}" == "" ]; then
			git pull --rebase
		fi
		NEW_HEAD=`git log --oneline -n1 | awk '{print $1}'`
	else
		echo "Unsupported version control system ${VCS}"
		return 1
	fi

	if [ "${CURR_HEAD}" != "${NEW_HEAD}" ]; then
		# we had updates, clear the stamps, ignore missing
		Q "rm ${TOP}/out/${DISTRO11S_BOARD}/stamps/${NAME}*" || continue
	fi

	if [ "${TAG}" != "" ]; then
		Q pushd .
		cd ${SRCDIR}
		git fetch
		git checkout -q ${TAG}
		Q popd
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
	PKG=`echo ${1} | cut -d '.' -f 1`
	STAMPFILE=${STAMPS}/${1}
	shift 1
	if [ ! -e ${STAMPFILE} -o ${FORCE_BUILD} -eq 1 ]; then
		eval "$*" || exit 1
		touch ${STAMPFILE}
	fi
	VERSION_FILE=${STAGING}/etc/distro11s-versions.d/${PKG}
	if [ -d src/${PKG} ]; then
	# Add versioning for each package
		VERSION=`pkg_version git src/${PKG}`
	else
		# check if i'm already in the directory of the package source
		if pwd | grep -q src/"${PKG}"$; then
			VERSION=`pkg_version git .`
		fi
	fi
	if [ "${VERSION}" = "" ]; then
		echo ${PKG} "[builtin to distro11s]" > ${VERSION_FILE}
	else
		echo ${PKG} ${VERSION} > ${VERSION_FILE}
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
		if sudo -n ls &> /dev/null; then
			echo "Active sudo credentials found, proceeding..."
		elif ! tty -s; then
			echo "Error: no sudo for non-interactive user ${USER}"
			exit -42
		else
			MSG="Use sudo? [Yn]"
			warn_user ${*}
			MSG=""
		fi
	fi
}

function pkg_version {
	if [ ${1} = "git" ]; then
		Q pushd ${2}
		INFO=`git branch -v | grep '*' | awk '{print $2, $3}'`
		if [ "${INFO}" = "(no branch)" ]; then
			#not on a branch, we want to log SHA anyway
			CURR_HEAD=`git log -n1 --format=%H`
			INFO="${INFO} ${CURR_HEAD}"
		fi
		# if not on a branch INFO will be (no branch)
		LOCAL_BRANCH=`git name-rev --name-only HEAD`
		TRACKING_REMOTE=`git config branch.$LOCAL_BRANCH.remote`
		if [ "${TRACKING_REMOTE}" = "" ]; then
			REMOTE_URL="(dev no-remote)"
		else
		REMOTE_URL=`git config remote.$TRACKING_REMOTE.url`
		fi
		echo ${INFO} ${REMOTE_URL}
		Q popd
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

# put common cleanup steps you definitely want executed on exit here
function cleanup {
	# some scripts may mount this for chroot builds
	sudo umount ${STAGING}/src &> /dev/null
}

trap cleanup INT HUP QUIT TERM EXIT

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
COMMONCONF=${TOP}/board/board.conf
if [ ! -e ${COMMONCONF} ]; then
	echo "Missing common board configuration (${COMMONCONF})"
	exit 1
fi
source ${COMMONCONF}

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
export LDFLAGS="-L${STAGING}/lib -L${STAGING}/usr/lib -L${STAGING}/usr/local/lib -L${STAGING}/usr/lib/x86_64-linux-gnu -L${STAGING}/usr/lib/i386-linux-gnu"

if [ "${FORCE_BUILD}" = "" ]; then
	FORCE_BUILD=0
fi

root_check
