#! /bin/bash

source `dirname $0`/common.sh

# Create a release from a fresh checkout
PKG=distro11s
GIT_URL=git@github.com:cozybit/distro11s

function build_for_board {
	rm -rf src/*
	echo "Configuring..."
	echo "$(cat <<EOF
DISTRO11S_BOARD=${1}
DISTRO11S_SRC=${PWD}/src
DISTRO11S_OUT=${PWD}/out
DISTRO11S_JOBS=${CORES}
DISTRO11S_HOST_IP=192.168.55.1
DISTRO11S_STATIC_IFACE=eth0
DISTRO11S_STATIC_IP=192.168.55.2
DISTRO11S_STATIC_NM=255.255.255.0
DISTRO11S_SSHFS_AUTOMOUNT_PATH=""
DISTRO11S_GIT_REFERENCE=${DISTRO11S_GIT_REFERENCE}
EOF
)" > distro11s.conf
	./scripts/fetch.sh || { echo Failed to fetch source; exit 1; }
	./scripts/build.sh || { echo Failed to fetch source; exit 1; }
}

CORES=2
COMMAND=""
VERSION=""
BOARDS=""
usage="$0 [-c <version>] [-p <version>] [-j <version>] -b <board> [-h]"
while getopts "c:p:j:hb:" options; do
	case $options in
		c ) VERSION=$OPTARG
			COMMAND=CREATE;;
		p ) VERSION=$OPTARG
			COMMAND=PUSH;;
		j ) CORES=$OPTARG;;
		b ) BOARDS=$OPTARG;;
		h ) COMMAND=HELP
			echo Options:
			echo "-c <version>		Creates a release with version number <version>"
			echo "-p <version>		Pushes a release with version number <version>"
			echo "-j <jobs>			Specifies the number of simultanious jobs"
			echo "-h			Shows help"
			echo "--help"
			exit 1;;
		* ) echo $usage
			exit 1;;
	esac
done

[ "$COMMAND" == "" ] && { echo $usage; exit 1;}

if [ ! -f scripts/release.sh ]; then
	echo "Please run release script from the top of your working directory."
	exit 1
fi

DISTRO11S_GIT_REFERENCE=""
if [ "$DISTRO11S_SRC" == "" ]; then
	warn_user "WARNING: Setting DISTRO11S_SRC to an existing tree will speed up the release process."
else
	DISTRO11S_GIT_REFERENCE=${DISTRO11S_SRC}
fi

if [ ! -d $DISTRO11S_SRC ]; then
	echo "DISTRO11S_SRC $DISTRO11S_SRC does not exist."
	exit 1
fi

if [ "${BOARDS}" = "" ]; then
	echo "Please specify for which boards the release should be prepared"
	exit 1
fi

if [ "$COMMAND" == "CREATE" ]; then

	echo "creating $PKG version $VERSION"
	PKGDIR=/tmp/$PKG-$VERSION
	if [ -d $PKGDIR ]; then
		warn_user "About to blow away $PKGDIR as sudo."
		sudo rm -rf $PKGDIR || { echo Failed to delete $PKGDIR. Aborting release.; exit 1; }
	fi
	git clone $GIT_URL $PKGDIR || { echo Failed to fetch $PKG. Aborting release.; exit 1; }
	cd $PKGDIR
	git tag release-$VERSION

	cd ..
	tar --exclude '.git*' -czf $PKG-src-$VERSION.tar.gz $PKG-$VERSION || { echo Failed to create the archive. Aborting release.; exit 1; }
	cd ${PKGDIR}

	# Build for each board
	for b in ${BOARDS}; do
		build_for_board $b
	done

	# TODO: now we must test each board.  Perhaps some of this can be
	# automated?  Perhaps the binaries for the boards should be captured
	# somewhere?

elif [ "$COMMAND" == "PUSH" ]; then
	cd /tmp/$PKG-$VERSION || { echo Failed to access to $PKG-$VERSION. Can not push tags.; exit 1; }
	git push --tags || { echo Failed to push.; exit 1; }

else
	echo "Please specify a valid command."
	exit 1
fi
