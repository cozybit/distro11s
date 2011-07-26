#!/bin/bash

source `dirname $0`/common.sh

DEV=$1

root_check "This script runs fdisk/mkdosfs/mkfs/etc on ${DEV}"

CHECK=`sudo fdisk -l ${DEV} | wc -l`

if [ "$CHECK" != "0" ]; then
  

   PARTITIONS=`mount | grep ${DEV} | awk '{print $1}'`
   for part in ${PARTITIONS}; do
       sudo umount ${part} > /dev/null
       [ "$?" != "1" ] || { echo "Error: problem unmouting ${part}. Aborting provisioning"; exit 1; }
   done

   echo "Creating partition table"
   sudo dd if=/dev/zero of=${DEV} count=2 bs=512 > /dev/null
   echo -e -n n\\np\\n1\\n\\n\\na\\n1\\nw\\n | sudo fdisk ${DEV} > /dev/null
   echo "Formating the partitions"
   sudo mkfs -t ext3 -m 1 -v ${DEV}1
   [ "$?" != "1" ] || { echo "Error: problem formating the EXT partition. Aborting provisioning"; exit 1; }
   echo "Mounting ${DEV}1"
   sudo mkdir -p /mnt/distross
   sudo mount ${DEV}1 /mnt/distross
   [ "$?" != "1" ] || { echo "Error: problem mounting the partition ${DEV}1. Aborting provisioning"; exit 1; }
   echo "Copying the file system to ${DEV}1"
   sudo cp -rav ${DISTRO11S_OUT}/${DISTRO11S_BOARD}/staging/* /mnt/distross > /dev/null
   [ "$?" != "1" ] || { echo "Error: copying the file system to ${DEV}1. Aborting provisioning"; exit 1; }
   sudo grub-install --root-directory=/mnt/distross ${DEV}
   sudo cp ${DISTRO11S_OUT}/${DISTRO11S_BOARD}/bzImage /mnt/distross/boot/
   echo "$(cat <<EOF
root (hd0, msdos1)
linux /boot/bzImage root=/dev/sda1
boot
EOF
)" > /tmp/grub.cfg
   sudo mv /tmp/grub.cfg /mnt/distross/boot/grub/
   sudo umount ${DEV}1
   rm -rf /mtn/distross
   echo "DISTRO11S PROVISIONING COMPLETE!!"
 
else
   echo "${DEV} is not a valid device. Please use a connected device"
   exit 1
fi
