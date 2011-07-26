#!/bin/bash
source `dirname $0`/../../scripts/common.sh
echo "options ath9k debug=0xfffffeff nohwcrypt=1" >> ${STAGING}/etc/modprobe.d/local
