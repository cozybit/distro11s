#!/bin/bash
# Copyright (c) 2013 cozybit Inc.
#
# All rights reserved
#

DRIVE=/mnt/distross
USAGE="Usage: ${0} [-d <device>] [-h] [-i] [-r] [-n <name>] [-v]"
INSTALLER=n
VERBOSE=n
# By default, some configuration variables come from the distro11s.conf file.
# Alternatively, they can come from the environment.
CONFIG_OVERRIDE=n
HOSTNUM=""

while getopts "d:ohin:v" options; do
    case $options in
        d ) DEV=${OPTARG};;
        o ) CONFIG_OVERRIDE='y';;
        i ) INSTALLER='y';;
        n ) HOSTNUM=${OPTARG};;
        v ) VERBOSE='y';;
        h ) echo "Options:"
            echo "-d <device>    Set the device to provision"
            echo "-n <number>    The host number of the device you are provisioning"
			echo "               If -i is set, this is the initial host number that"
			echo "               will be used by the installer."
            echo "-i             Set the USB Installer creation mode"
            echo "-v             set verbose mode"
            echo "-h             Print help"
            ;;
        * ) echo ${USAGE}
            exit 1;;
    esac
done

[ "${DEV}" == "" ] && { echo "Error: Specify a device to provision distro11s. "; exit 1; }

if [ "${VERBOSE}" == "y" ]; then
    set -x
fi

if [ "${CONFIG_OVERRIDE}" = "n" ]; then
	source `dirname $0`/common.sh
	root_check "This script runs fdisk/mkdosfs/mkfs/etc on ${DEV}"
	STAGING=${DISTRO11S_OUT}/${DISTRO11S_BOARD}/staging
	KERNEL=${DISTRO11S_OUT}/${DISTRO11S_BOARD}/bzImage
fi

ISVALID=`sudo fdisk -l ${DEV} | wc -l`

if [ "${ISVALID}" != "0" ]; then

   PARTITIONS=`sudo mount | grep ${DEV} | awk '{print $1}'`
   for part in ${PARTITIONS}; do
       sudo umount ${part} > /dev/null
       [ "$?" != "0" ] && { echo "Error: problem unmouting ${part}. Aborting distro11s provisioning"; exit 1; }
   done

   echo "Creating the partition table in ${DEV}"
   sudo dd if=/dev/zero of=${DEV} count=2 bs=512 > /dev/null
   V=`fdisk -v`
   if [ "${V}" != "fdisk (util-linux-ng 2.17.2)" ]; then
       echo "WARNING: unkown version of fdisk.  Proceeding anyway."
   fi
   echo -e -n n\\np\\n1\\n\\n\\na\\n1\\nw\\n | sudo fdisk ${DEV} > /dev/null
   [ "$?" != "0" ] && { echo "Error: problem reading the partition table of ${DEV}. Aborting distro11s provisioning"; exit 1; }
   echo "Rereading the partition table of ${DEV}"
   sudo sfdisk -R ${DEV}
   count=5
   while [ ${count} -gt 0 ]; do
       [ -e ${DEV}1 ] && break
       count=$((${count}-1))
       sleep 1
   done
   [ ! -e ${DEV}1 ] && { echo "Error: failed to find new partition ${DEV}1"; exit 1;}
   echo "Creating the EXT4 file system for ${DEV}1"
   sudo mkfs -t ext4 ${DEV}1
   [ "$?" != "0" ] && { echo "Error: problem formating the partition. Aborting distro11s provisioning"; exit 1; }
   echo "Mounting ${DEV}1"
   sudo mkdir -p ${DRIVE}
   sudo mount ${DEV}1 ${DRIVE}
   [ "$?" != "0" ] && { echo "Error: problem mounting the partition ${DEV}1. Aborting distro11s provisioning"; exit 1; }
   echo "Provisioning distro11s onto ${DEV}1"
   sudo cp -ra ${STAGING}/* ${DRIVE}
   [ "$?" != "0" ] && { echo "Error: provisioning step failed. Aborting distro11s provisioning"; exit 1; }
   echo "Copying the kernel"
   sudo cp ${KERNEL} ${DRIVE}/boot/
   echo "Installing GRUB"
   sudo grub-install --root-directory=${DRIVE} ${DEV}
   [ "$?" != "0" ] && { echo "Error: grub installation failed. Aborting distro11s provisioning"; exit 1; }

   if [ "${INSTALLER}" == "n" ]; then
	   # In this case, we're actually provisioning the harddrive that will be
	   # plopped into the device and booted.  So just put grub down and be
	   # done.
       echo "Creating grub config file"
       echo "$(cat <<EOF
set root=(hd0,msdos1)
linux /boot/bzImage root=/dev/sda1 sysrq=1 console=ttyS0,115200n8 video=card0 fbcon=scrollback:512k
boot
EOF
)" > /tmp/grub.cfg
	   sudo mv /tmp/grub.cfg ${DRIVE}/boot/grub/

   else
	   # In this case, we are making a USB installer.  This thing must boot
	   # itself then copy the staged rootfs over to the local harddrive on the
	   # device.  To do this it needs a special rc.local script and a copy of
	   # the staged rootfs.
       echo "Creating grub config file"
       echo "$(cat <<EOF
set root=(hd0,msdos1)
linux /boot/bzImage root=/dev/sdb1 rootdelay=10
boot
EOF
)" > /tmp/grub.cfg
	sudo mv /tmp/grub.cfg ${DRIVE}/boot/grub/
	echo "Copying the file system to provision"
	sudo mkdir ${DRIVE}/staging
	sudo cp -ra ${STAGING}/* ${DRIVE}/staging
	echo "Adding provisioning rc.local script and its dependencies"
	sudo cp ${TOP}/scripts/provisioning.sh ${DRIVE}/usr/local/bin/
	sudo cp ${TOP}/scripts/installer.rc.local ${DRIVE}/etc/rc.local
	sudo chmod +x ${DRIVE}/etc/rc.local
	# We don't want to apt-get install grub because it will mess with our
	# MBR.  But we need it on the installer.  So grab it from the host
	# system.  Note the smartest thing to do.  Oh well.
	sudo cp /usr/bin/grub-* ${DRIVE}/usr/bin/ || exit 1
	sudo cp /usr/sbin/grub-* ${DRIVE}/usr/sbin/ || exit 1
	sudo cp -r /usr/lib/grub ${DRIVE}/usr/lib/
	sudo chroot ${DRIVE} apt-get update || exit 1
	sudo chroot ${DRIVE} apt-get -f install -y --force-yes || exit 1
	sudo chroot ${DRIVE} apt-get update
	sudo chroot ${DRIVE} apt-get -y --force-yes install sudo libdevmapper1.02.1 || exit 1

	#Removing meshkit service from the usb installer
	INSSERV=`sudo which insserv`
	[ -z "$INSSERV" ] && INSSERV=/usr/lib/insserv/insserv
	sudo $INSSERV -r ${DRIVE}/etc/init.d/meshkit || exit 1
   fi

   if [ "${HOSTNUM}" != "" ]; then
        echo "Configuring hostnumber"
        echo ${HOSTNUM} >> /tmp/distro11s-hostnumber
		if [ "${INSTALLER}" == "y" ]; then
			sudo mv /tmp/distro11s-hostnumber ${DRIVE}/etc/hostnumber
		else
			sudo mv /tmp/distro11s-hostnumber ${DRIVE}/etc/
		fi
   fi

   # allow provision-time override of meshconf file
   if [ "${DISTRO11S_MESHKIT_CONFIG}" != "" ]; then
	   if [ ! -e ${DISTRO11S_MESHKIT_CONFIG} ]; then
		   echo "meshkit config file ${DISTRO11S_MESHKIT_CONFIG} does not exist"
		   exit 1
	   fi
	   sudo mkdir -p ${DRIVE}/etc/meshkit/
	   sudo cp ${DISTRO11S_MESHKIT_CONFIG} ${DRIVE}/etc/meshkit/meshkit.conf
	   if [ "${INSTALLER}" == "y" ]; then
		   sudo mkdir -p ${DRIVE}/staging/etc/meshkit/
		   sudo cp ${DISTRO11S_MESHKIT_CONFIG} ${DRIVE}/staging/etc/meshkit/meshkit.conf
	   fi
   fi

   echo "Unmounting ${DEV}1"
   sudo umount ${DEV}1
   sudo rm -rf ${DRIVE}

   if [ "$INSTALLER" == "n" ]; then
       echo "distro11s provisioning complete!"
   else
       echo "distro11s usb installer created!"
   fi

else
   echo "${DEV} is not a valid device. Please use a connected device"
   exit 1
fi
