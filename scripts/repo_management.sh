#!/bin/bash
source `dirname $0`/common.sh

# check if given branch is in local repo.
# branch_in_local <branch>
branch_in_local() {
	_BRANCH=${1}
	[ "`git branch | grep $_BRANCH`" != "" ]
}
TEMP_REPO="${TOP}/repo_mgmt/o11s"
O11S_URL=git@github.com:cozybit/open80211s
WTURL=git://git.kernel.org/pub/scm/linux/kernel/git/linville/wireless-testing.git
WTREPO=wt_repo
WTBRANCH=wt

# create temporary copy of remote we'll work in. We do this as a (not-so) quick
# and dirty way of checking out all the remote branches at once.
# TODO: this is slow, we should only clone once to have a repo management copy,
# then fetch new branches and updates.
if [ ! -d ${TEMP_REPO} ]; then
	mkdir -p ${TEMP_REPO}
	git clone --reference ${DISTRO11S_SRC}/kernel --progress -l ${O11S_URL} ${TEMP_REPO}
	pushd ${TEMP_REPO}
else
	pushd ${TEMP_REPO}
	git fetch
fi

# check out local copies of all the branches
echo "checking out all remote branches"
RBRANCHES="`git branch -r | grep -e origin | grep -v -e HEAD -e master | awk -F"/" '{print $2}'`"
for rbranch in ${RBRANCHES}; do
	if [ ! `branch_in_local $rbranch` ]; then
		git checkout $rbranch || exit 1
		git reset --hard origin/$rbranch  || exit 1
	else
		git checkout origin/$rbranch -b $rbranch -t || exit 1
	fi
done
FT_BRANCHES=`git branch | grep "ft-" | sed -e"s/\*/ /"`

#Translate long options to short
for arg
do
        delim=""
        case "$arg" in
                --updatewt) args="${args}-u ";;
                --recreatebe) args="${args}-r ";;
                --help) args="${args}-h ";;
                # pass through anything else
                *) [[ "${arg:0:1}" == "--" ]] || delim="\""
                args="${args}${delim}${arg}${delim} ";;
        esac
done
# reset the translated args
eval set -- $args

COMMAND=""
UPDATE_WT="n"
RECREATE_BE="n"
usage="$0 [--updatewt] [--recreatebe]"
while getopts "urh" options; do
        case $options in
                u ) VERSION=$OPTARG
		    UPDATE_WT="y";;
                r ) VERSION=$OPTARG
		    RECREATE_BE="y";;
                h ) COMMAND=HELP
                        echo Options:
			echo "-u 			Fetch wt and rebase all the branches"
			echo "--updatewt"
			echo "-r			Recreate bleeding edge"
			echo "--recreatebe"
                        echo "-h                        Shows help"
                        echo "--help"
                        exit 1;;
                * ) echo $usage
                        exit 1;;
        esac
done

if [ "${UPDATE_WT}" == "y" ]; then

	ISREPO=`grep "kernel.org" .git/config`
	if [ "${ISREPO}" == "" ]; then
		echo "Adding WT remote repository"
		git remote add -f ${WTREPO} ${WTURL} || exit 1
		git checkout -b ${WTBRANCH} ${WTREPO}/master || exit 1
	else
		git fetch ${WTREPO} || exit
	fi
	git checkout ${WTBRANCH} || exit 1
	echo "Updating wt with the remote repository "
	git reset --hard ${WTREPO}/master
	echo "Rebasing all the FT branches"
	for branch in ${FT_BRANCHES}; do
		echo "Rebasing branch ${branch}"
		git rebase ${WTBRANCH} ${branch} || exit 1
	done
	echo "Rebasing bleeding-edge"
	#git rebase ${WTBRANCH} bleeding-edge || exit 1
fi

# TODO: Recreate option should recreate a given branch, instead of just
# bleeding-edge
if [ "${RECREATE_BE}" == "y" ]; then
	# rebuild bleeding-edge from wt and ft- branches
	git checkout wt -b bleeding-edge-new
	for branch in ${FT_BRANCHES}; do
		echo "merging branch ${branch}"
		git merge --no-ff --log $branch || exit 1
	done
fi
# TODO: build and test, if successful, 'git push -f'
