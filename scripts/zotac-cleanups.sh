#!/bin/bash
source `dirname $0`/common.sh

#Load ath9k module with nohwcrypt parametar at boot time
add_text "options ath9k nohwcrypt=1" ${STAGING}/etc/modprobe.d/local.conf

#Activate syntax highlightning
echo "$(cat <<EOF
syntax on
EOF
)" > /tmp/vimrc
sudo mv /tmp/vimrc ${STAGING}/root/.vimrc

#Install & configure acpid to enable clean shutdown when pressing the power
#button
sudo mount proc ${STAGING}/proc/ -t proc
sudo chroot ${STAGING} apt-get -y --force-yes install acpid
sudo umount ${STAGING}/proc/

#Enabling coredumps for meshtkid
if [ "`grep ulimit ${STAGING}/usr/local/bin/meshkitd`" == "" ]; then
	sed '/bash/ a\
ulimit -c 100000' ${STAGING}/usr/local/bin/meshkitd > /tmp/meshkitd
	mv /tmp/meshkitd ${STAGING}/usr/local/bin/meshkitd
	chmod 755 ${STAGING}/usr/local/bin/meshkitd
fi

#Seting coredump output folder
mkdir -p ${STAGING}/var/log/dumps
sudo chown -R root.root ${STAGING}/var/log/dumps
sudo chmod -R 1777 ${STAGING}/var/log/dumps
add_text "#Core Files Destination: core_filename_pid_time_signal" ${STAGING}/etc/sysctl.conf
add_text "kernel.core_pattern=/var/log/dumps/core_%e_%p_%t_%s" ${STAGING}/etc/sysctl.conf

# set regulatory domain
echo "configuring regulatory domain: ${DISTRO11S_REGDOMAIN}"
echo "sed -i \"s/^REGDOMAIN=/REGDOMAIN=${DISTRO11S_REGDOMAIN}/\" ${STAGING}/etc/default/crda" | sudo sh
# CRDA debian package expects iw in /usr/sbin/...
sudo ln -s ${STAGING}/usr/local/sbin/iw ${STAGING}/usr/sbin/iw

# Disable DNS lookup - Makes SSH login faster
sudo chmod 666 ${STAGING}/etc/ssh/sshd_config
add_text "UseDNS no" ${STAGING}/etc/ssh/sshd_config
sudo chmod 644 ${STAGING}/etc/ssh/sshd_config
