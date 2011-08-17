#!/bin/bash
source `dirname $0`/common.sh

#Load ath9k module with nohwcrypt parametar at boot time
echo "options ath9k nohwcrypt=1" >> ${STAGING}/etc/modprobe.d/local

#Install & configure acpid to enable clean shutdown when pressing the power
#button
sudo mount proc ${STAGING}/proc/ -t proc
sudo chroot ${STAGING} apt-get -y --force-yes install acpid
sudo umount ${STAGING}/proc/
