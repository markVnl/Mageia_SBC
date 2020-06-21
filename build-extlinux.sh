#!/bin/bash
ks="$1"

if [ -z "$1" ] ;then
  echo $0 path/to/file.ks
  exit 1
fi

img=$(echo $ks|rev|cut -f 1 -d "/"|rev|sed s/\.ks//g)

time appliance-creator --config=${ks} --name="$img" --debug --no-compress

rm -f ${img}/*.xml
chown -R $SUDO_USER. $img


#
# FIXME
#

echo "Setting boot partition..."
( echo a ; echo 2 ; echo w )  | sudo fdisk  ${img}/$img-img.raw > /dev/null 2>&1

#
# END FIXME
#
