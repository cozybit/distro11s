#!/bin/bash

# This script allows to test the process of creating a new QEMU target

function die(){
        log ${*}
        exit -1
}

function log(){
	echo ${*} >> ${TST_PATH}/distro11s_test.log
}

function generate_config(){

# Generate a distro11s config file
	echo "$(cat <<EOF
DISTRO11S_BOARD=qemu
DISTRO11S_SRC=\${PWD}/src
DISTRO11S_OUT=\${PWD}/out
DISTRO11S_JOBS=4
DISTRO11S_HOST_IP=192.168.55.1
DISTRO11S_HOSTNAME=\${DISTRO11S_BOARD}
DISTRO11S_STATIC_IFACE=eth0
DISTRO11S_STATIC_IP=192.168.55.2
DISTRO11S_STATIC_NM=255.255.255.0
DISTRO11S_AUTO_INCREMENT_INSTALLER=0
DISTRO11S_SSHFS_AUTOMOUNT_USER=\${USER}
DISTRO11S_SSHFS_AUTOMOUNT_PATH=/home/guillermo/Projects
DISTRO11S_GIT_REFERENCE=\${PWD}/src
DISTRO11S_SSH_PUB_KEY=\${HOME}/.ssh/id_rsa.pub
DISTRO11S_ROOT_PW='bilbao'
EOF
)" > distro11s.conf

}

DISTRO11S_GIT=git://github.com/cozybit/distro11s.git
TST_PATH=/tmp/test_distro11s-$(date +%F_%H-%M)

mkdir -p ${TST_PATH}
cd ${TST_PATH}
git clone ${DISTRO11S_GIT} distro11s || die "Failed to clone the git repository. Aborting"
cd distro11s

generate_config

log "Fetching the source for all the packages..."
./scripts/fetch.sh || die "Failed fetching the sources. Aborting"
log "- SUCCEED"
log "Creating a QEMU environment..."
yes | ./scripts/build.sh || die "Failed building the packages. Aborting"
log "- SUCCEED"

log "Launching qemu..."
./board/qemu/qemu.sh &> /dev/null &

log "Waiting for connectivity..."
while true; do
        ping -c 1 192.168.55.2 && break
        sleep 1
done

log "Running test-XXX-template.sh"
OPEN=`ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@192.168.55.2 "cd /usr/local/share/hwsim_tests/ && ./test-XXX-template.sh"`

TEST=FAIL
echo ${OPEN} | grep PASS &>/dev/null && TEST=PASS
log "Test for Open Mesh: ${TEST}"

SECURE=`ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@192.168.55.2 "cd /usr/local/share/hwsim_tests/ && ./test-XXX-template.sh -s"`

TEST=FAIL
echo ${SECURE} | grep PASS &>/dev/null && TEST=PASS
log "Test for Secure Mesh: ${TEST}"

log "Halting QEMU"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@192.168.55.2 halt &> /dev/null || die "Failed to halt QEMU"
