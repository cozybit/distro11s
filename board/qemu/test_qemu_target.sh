#!/bin/bash

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


DISTRO11S_GIT=git@github.com:cozybit/distro11s.git
TST_PATH=/tmp/test_distro11s

mkdir -p ${TST_PATH}
cd ${TST_PATH}
git clone ${DISTRO11S_GIT} distro11s
cd distro11s

generate_config

log "Fetching the source for all the packages..."
./scripts/fetch.sh || die "Failed fetching the sources. Aborting"
log "- SUCCEED"
log "Creating a QEMU environment..."
./scripts/build.sh || die "Failed building the packages. Aborting"
log "- SUCCEED"

log "Launching qemu..."
./board/qemu/qemu.sh &> /dev/null &

# Wait for qemu to boot
log "Waiting for connectivity..."
while true; do
        ping -c 1 192.168.55.2 && break
        sleep 1
done

log "Running the test-high-load-short"
RESULTS=`ssh root@192.168.55.2 "cd /usr/local/share/hwsim_tests/ && ./test-high-load-short.sh"`
log "Halting QEMU"
ssh root@192.168.55.2 halt &> /dev/null || die "Failed to halt QEMU"

TEST=FAIL
echo ${RESULTS} | grep PASS &>/dev/null && TEST=PASS

log "QEMU Distro11s test: ${TEST}"
