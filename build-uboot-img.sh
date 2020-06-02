#!/bin/bash
ks="$1"

if [ -z "$1" ] ;then
  echo $0 path/to/file.ks
  exit 1
fi

img=$(echo $ks|rev|cut -f 1 -d "/"|rev|sed s/\.ks//g)

time appliance-creator --config=${ks} --name="$img" --logfile="$img.log" --debug --no-compress

chown -R $SUDO_USER. $img


#
# FIXME
#

# hack to configure grub2
losetup -f -P ${img}/$img-img.raw
if [[ $? -ne 0 ]]; then
   echo -e "\nFailed to finalize aarch64 image!\n"
   exit $?
fi
loopdev=$(losetup | grep $img | awk 'END{print $1}')

tmp=`/bin/mktemp -d --suffix aarch64-img`

echo -e "\n\nRemounting image attached to $loopdev on $tmp ..."
mount ${loopdev}p2 ${tmp}
mount ${loopdev}p1 ${tmp}/boot/EFI
mount --bind /proc ${tmp}/proc
mount --bind /dev  ${tmp}/dev
mount --bind /sys  ${tmp}/sys

# TODO : 
#  Remove GRUB_DISABLE_OS_PROBER="true" from grub defaults
#  cp -P /boot/EFI/EFI/mageia/grubaa64.efi /boot/EFI/EFI/BOOT/BOOTAA64.EFI for prestine u-boot 
chroot ${tmp} /bin/bash -c "/usr/sbin/grub2-install --target=arm64-efi --efi-directory=/boot/EFI --bootloader-id=mageia --no-bootsector --no-nvram"
chroot ${tmp} /bin/bash -c "/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg"


echo "Umounting image from $tmp and detaching ${loopdev} ..."
umount -R ${tmp}
losetup -d ${loopdev}
rm -rf ${tmp}

echo "Setting 1st (EFI) as boot partition..."
( echo a ; echo 1 ; echo w )  | sudo fdisk  ${img}/$img-img.raw > /dev/null 2>&1

echo -e "done\n"

#
# END FIXME
#
