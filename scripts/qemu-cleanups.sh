#!/bin/bash

source `dirname $0`/common.sh

if [ -e ${STAMPS}/qemu-cleanups ]; then
	exit 0;
fi

# Launch a serial terminal at boot
echo "T0:23:respawn:/sbin/getty -n -l /bin/autologin.sh -L ttyS0 38400 linux" >> ${STAGING}/etc/inittab

# Automatically login as root
echo "$(cat <<EOF
#!/bin/sh
exec /bin/login -f root
EOF
)" > ${STAGING}/bin/autologin.sh
chmod +x ${STAGING}/bin/autologin.sh

# disable root password
sed 's/^root:\*:\(.*\)$/root::\1/' < ${STAGING}/etc/shadow >  ${STAGING}/etc/shadow.new
mv  ${STAGING}/etc/shadow.new ${STAGING}/etc/shadow

touch ${STAMPS}/qemu-cleanups
