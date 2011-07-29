#!/bin/bash

DRIVE=/mnt/distross
REBOOT=n
USAGE="Usage: ${0} [-d <device>] [-h] [-i] [-r] [-u] [-n <name>] [-v]"
INSTALLER=n
USB_MODE=n
VERBOSE=n

while getopts "d:ruhin:v" options; do
    case $options in
        d ) DEV=${OPTARG};;
        r ) REBOOT='y';;
        u ) USB_MODE='y';;
        i ) INSTALLER='y';;
        n ) HOSTNAME=${OPTARG};;
        v ) VERBOSE='y';;
        h ) echo "Options:"
            echo "-d <device>    Set the device to provision"
            echo "-r             Reboot the local machine after provisioning"
            echo "-u             Set the USB provisioning mode"
            echo "-n <name>      Change the hostname of the provisioning system"
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

if [ "${USB_MODE}" == "n" ]; then

    source `dirname $0`/common.sh
    root_check "This script runs fdisk/mkdosfs/mkfs/etc on ${DEV}"
    STAGING=${DISTRO11S_OUT}/${DISTRO11S_BOARD}/staging
    KERNEL=${DISTRO11S_OUT}/${DISTRO11S_BOARD}/bzImage
    if [ "${INSTALLER}" == "y" ]; then
        PROV_SCRIPT_PATH=/root/provisioning.sh
        HOSTNAME=usbinstaller
    fi
else
    STAGING=/staging
    KERNEL=/boot/bzImage
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
   echo "Creating the EXT3 file system for ${DEV}1"
   sudo mkfs -t ext3 -m 1 ${DEV}1
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

       echo "Creating grub config file"
       echo "$(cat <<EOF
set root=(hd0,msdos1)
linux /boot/bzImage root=/dev/sda1
boot
EOF
)" > /tmp/grub.cfg
   sudo mv /tmp/grub.cfg ${DRIVE}/boot/grub/

   else

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
       echo "Adding provisioning script to rc.local"
       sudo cp ${TOP}/scripts/provisioning.sh ${DRIVE}${PROV_SCRIPT_PATH}
       sudo chmod +x ${DRIVE}${PROV_SCRIPT_PATH}
       sudo sed -i -e '$d' ${DRIVE}/etc/rc.local
       echo -e "${PROV_SCRIPT_PATH} -d /dev/sda -u -n zotact  \nexit 0" >> ${DRIVE}/etc/rc.local

   fi

   if [ "${HOSTNAME}" != "" ]; then
        echo "Configuring hostname"
        echo ${HOSTNAME} >> /tmp/hostname
        sudo mv /tmp/hostname ${DRIVE}/etc/
        sudo sed -i '$a127.0.0.1     '${HOSTNAME}'' ${DRIVE}/etc/hosts
   fi

   echo "Unmounting ${DEV}1"
   sudo umount ${DEV}1
   sudo rm -rf ${DRIVE}

   if [ "$INSTALLER" == "n" ]; then
       echo "distro11s provisioning complete!"
   else
       echo "distro11s usb installer created!"
   fi

   if [ "${REBOOT}" == "y" ]; then
       echo "Rebooting the system"
       sudo reboot
   fi

else
   echo "${DEV} is not a valid device. Please use a connected device"
   exit 1
fi
