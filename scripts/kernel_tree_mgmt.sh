#!/bin/bash

# This script allows to run some of the basic management tasks needed by the
# o11s development workflow (see more in ${DISTRO11S}/doc/open80211s-kernel.txt)
# 
# Implemented functionalities:
#
# - Rebase all the feature branches with the HEAD of wireless-testing. The
#   rebased branches (ft-*-can) will be available in your working directory,
#   ready to be tested and pushed upstream.
#
#   Also, if the script detects that a feature branch is already present in the
#   latest wireless-testing, it will delete that branch from the repository.
#
# - Recreate bleeding-edge: it will rebase all the feature branches with the
#   latest WT and then merge them all in bleeding-edge-can.
#
# - Automatic testing: if using the flag -t with any of the features above, it
#   will build, install and test the candidate branches.
#
# Tips & Tricks:
#
# - The script uses stamp files in order to be able to resume its activity if
#   it fails performing any operation. So, if you find any merging or rebasing
#   issue, please fix the conflicts and run the script again (with the same
#   options).
#
# - This script produces two types of branches:
#
#   + candidate branches (*-can): they represent the final product of the script.
#     They are meant to be tested and pushed by the release manager.
#
#   + temporary branches (*-tmp): these are temporary branches that are deleted
#     once the script finishes. If the script is interrupted for any reason, 
#     they will be.



source `dirname $0`/common.sh

[ "${DEBUG}" == "" ] && DEBUG=0
[ "${DEBUG}" == 1 ] && set -x

# Global variables
O11S_URL=git@github.com:cozybit/open80211s
WT_URL=git://git.kernel.org/pub/scm/linux/kernel/git/linville/wireless-testing.git

function die(){
	echo $*
	exit -1
}


function init(){

	cd ${DISTRO11S_SRC}/kernel

	echo "-- Getting an available branch in the repository"
	#TODO: make this work when a branch has the * next to it
	# Get the name of any branch available in the working directory 
	AVAILABLE_BRANCH=`git branch | grep -m1 -v -e '-tmp' -e '-can' -e '*'`
	
	echo "-- Detecting the names of the repositories"
	#Get the right name of the repos
	O11S=$(get_repo_name ${O11S_URL})
	WT=$(get_repo_name ${WT_URL})

	[ "${O11S}" == "" ] && die "Failed to get open11s repository name."

	#If WT repo does not exist, then add it and fetch the code
	if [ "${WT}" == "" ]; then
		echo "-- WT repository not found. Adding it..."
		WT=wt-auto
		git remote add ${WT} ${WT_URL} || die "Failed to add WT as remote repository."
	fi

	echo "-- Fecthing from ${O11S}"
	git fetch ${O11S} || die "Failed to fetch ${O11S}."
	echo "-- Fecthing from ${WT}"
	git fetch ${WT} || die "Failed to fetch ${WT}."
}

# TODO: make this function way faster by analyzing .git/config 
# Given a repo URL, this function returns the name of the remote repository in
# the working directory
# get_repo_name <repository_url>
function get_repo_name() {

	_REPO_URL=${1}	
	_ALL_REPOS=`git remote show` || die "Failed to get a list of all the remote repos avaiable."

	for repo in ${_ALL_REPOS}; do
		_MATCH=`git remote show ${repo} | grep "Fetch URL" | grep -e ${_REPO_URL}`
		[ "${_MATCH}" != "" ] && { echo ${repo}; break; }
	done
}

# Rebase all the feature branches onto the latest wireless testing
# rebase-ft <bleeding-edge>
function rebase-ft(){

	if [ "${1}" == "bleeding-edge" ]; then
		#tmp stands for "temporary"
		_SUFIX=tmp
	else
		#can stans for "candidate"
		_SUFIX=can
	fi

	_STMP_FILE=rebase-ft-${_SUFIX}.stmp
	_WT_BRANCH=wt-tmp
	_FT_BRANCHES=`git branch -r | grep "ft-" | awk -F'/' '{print$2}'`
	echo "-- About to rebase the next $(echo ${_FT_BRANCHES} | wc -w) feature branches: $_FT_BRANCHES"
	
	if [ ! -e ${_STMP_FILE} ]; then
		# etch the latest wireless-testing
		echo "-- Checking out ${WT}/master into ${_WT_BRANCH}"
		git checkout ${WT}/master -b ${_WT_BRANCH} || die "Failed to checkout ${WT}/master."
		touch ${_STMP_FILE}
	fi
	
	# Checkout every ft branch and rebase 
	for branch in ${_FT_BRANCHES}; do
		_ISREBASED=`grep ${branch} ${_STMP_FILE}`
		if [ "${_ISREBASED}" == ""  ]; then
			echo "-- Checking out origin/${branch} into ${branch}-${_SUFIX}"
	                git checkout origin/${branch} -b ${branch}-${_SUFIX} || \
				die "Failed to checkout origin/${branch}."
			#Creating stamp file
			echo "${branch}-${_SUFIX}" >> ${_STMP_FILE}
			echo "-- Rebasing ${branch}-${_SUFIX} onto ${_WT_BRANCH}"
			git rebase ${_WT_BRANCH} ${branch}-${_SUFIX} || \
				die "Failed to rebase ${branch}-${_SUFIX}. Please, solve the conflicts, git add and git rebase --continue. Then execute this script again to continue recreating the branch."

			# Check if the patches are already upstream. If they are, the
			# ft-branch is deleted both remotely and locally.
			if [ "`git rev-parse ${branch}-${_SUFIX}`" == "`git rev-parse ${_WT_BRANCH}`"  ]; then
				echo "-- Feature branch already upstream. Deleting branch localy and in the repository"
				git push ${O11S} :${branch} || die "Failed to delete the branch in the repository."
				git checkout ${AVAILABLE_BRANCH} || die "Failed to change the branch to ${_WT_BRANCH}."
				git branch -D ${branch}-${_SUFIX} || die "Failed to delete the branch ${branch}-${_SUFIX}"
				git branch -r -d ${O11S}/${branch} || die "Failed to delete the branch ${O11S}/${branch}"
			fi
		fi
	done
	echo "-- FT Branches rebasing complete! "
}

# Recreate bleeding-edge
# 1- It fetches and checks out all the ft branches in temporary branches.
# 2- It fetches the latest wt and merges it with all the temp ft branches.
function recreate_be(){

	rebase-ft bleeding-edge

	_BE_STMP_FILE=recreate_be.stmp
	_NEW_BE=bleeding-edge-can

        if [ ! -e ${_BE_STMP_FILE} ]; then
                #fetch latest wireless-testing
		echo "-- Checking out the latest ${WT}/master into ${_NEW_BE}"
                git checkout ${WT}/master -b ${_NEW_BE}
                touch ${_BE_STMP_FILE}
	else
		echo "-- Checking out ${_NEW_BE}"
		git checkout ${_NEW_BE}
        fi

	_TMP_FT_BRANCHES=`git branch | grep ft | grep -v can | grep tmp`
	echo "-- About to merge ${_NEW_BE} with the next $(echo ${_TMP_FT_BRANCHES} | wc -w) feature branches: $_TMP_FT_BRANCHES"
	# merge all temporary ft branches with the latest wireless testing
        for branch in ${_TMP_FT_BRANCHES}; do
                _ISMERGED=`grep ${branch} ${_BE_STMP_FILE}`
                if [ "${_ISMERGED}" == ""  ]; then
                        echo "${branch}" >> ${_BE_STMP_FILE}
			echo "-- Merging ${branch} with ${_NEW_BE}"
			git merge --no-ff --log ${branch} || \
			die "Failed to merge ${_NEW_BE} and ${branch}. Please, solve the conflicts and commit. Then execute this script to continue recreating the branch."
                fi
        done
	
	echo "-- Bleeding edge recreated --> ${_NEW_BE}"
}

# Delete all the temp branches and stamp files
function clean(){
	
	#_TMP_BRANCHES=`git branch | grep -e '-can'`
	echo "-- Switching to an availabe branch: ${AVAILABLE_BRANCH}"
	git checkout ${AVAILABLE_BRANCH} || die "Failed to checkout ${AVAILABLE_BRANCH}."
	_TMP_BRANCHES=`git branch | grep -e '-tmp'`
	for branch in ${_TMP_BRANCHES}; do
		git branch -d ${branch} || \
		git branch -D ${branch}
	done
	rm -f *.stmp &> /dev/null
}

#TODO: test this feature/function
# Build, Install and Test a particular branch
# It can run two type of tests: smoke or functional
# test <branch_name> <functional/smoke>
function test(){

	_BRANCH=${1}
	_TYPE=${2}

	#first build and install the kernel
	cd ${DISTRO11S_SRC}/kernel
	git checkout ${_BRANCH}
        FORCE_BUILD=1 ${TOP}/scripts/kernel.sh || die "Failed to build/install the kernel"
	
	#launch qemu in the background
        ${TOP}/board/qemu/qemu.sh &> /dev/null &
	
	#wait for qemu to boot
	while true; do
		ping -c 1 ${DISTRO11S_STATIC_IP} &> /dev/null && break
                sleep 2
	done

	if [ "${_TYPE}" == "functional" ]; then
		_TST=runall.sh
	else
		_TST=test-high-load-short.sh
	fi

	#TODO make sure that this line works
	_RESULTS=`ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${DISTRO11S_STATIC_IP} "cd /usr/local/share/hwsim_tests/ && ./${_TST}"`
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${DISTRO11S_STATIC_IP} halt &>/dev/null || die "Failed to halt qemu"

	_COUNT=`echo ${_RESULTS} | grep -c FAIL`
	
	[ ${_COUNT} -eq 0 ] && return 1
	
	return -1
}

COMMAND=""
TEST='n'
usage="$0 [-r] [-c] [-h] [-t]"
while getopts "rcht" options; do
        case $options in
                r ) COMMAND="REBASE";;
		t ) TEST='y';;
                c ) COMMAND="RECREATE";;
                h ) COMMAND="HELP"
                        echo Options:
                        echo "-r           Fetch wt and rebase all the ft branches"
                        echo "-c           Recreate bleeding edge"
			echo "-t           Build, install and test all the candidate branches"
                        echo "-h           Shows help"
                        exit 1;;
                * ) echo ${usage}
                        exit 1;;
        esac
done

[ "${COMMAND}" == "" ] && { echo "Please, select a valid option."; echo ${usage}; exit 1; }

[ "${DISTRO11S_BOARD}" != "qemu" ] && \
	die "Error: you must use a distro11s.conf configured for a qemu target."

QEMU_RUNNING=`ps aux | grep -c 'qemu/bzImage'`
[ "${TEST}" == "y" -a  ${QEMU_RUNNING} -gt 1 ] && die "There is another instance of QEMU running! Please, halt it."

init

if [ "${COMMAND}" == "REBASE" ]; then
	rebase-ft
	if [ "${TEST}" == "y" ]; then 
		CAN_FT_BRANCHES=`git branch | grep -e '-can' | grep -e 'ft-'`
		for branch in ${CAN_FT_BRANCHES}; do
			test ${branch} smoke
	        done
	fi
	
elif [ "${COMMAND}" == "RECREATE" ]; then
	recreate_be
	[ "${TEST}" == "y" ] && test bleeding-edge-can functional
fi

clean
