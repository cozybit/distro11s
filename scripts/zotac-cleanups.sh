#!/bin/bash
source `dirname $0`/common.sh
echo "options ath9k nohwcrypt=1" >> ${STAGING}/etc/modprobe.d/local
