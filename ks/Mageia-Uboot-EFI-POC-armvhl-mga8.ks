
# Basic setup information
install
keyboard us
lang en_US.UTF-8
rootpw mageia
timezone UTC
selinux    --disabled
firewall   --disabled
# On SBC's we are pretty sure know the device names
network    --bootproto=dhcp --device=eth0  --activate --onboot=on
#
# TODO : Figure out {systemd-homed, mandriva-everytime}.service
services   --enabled=sshd,chronyd --disabled=systemd-homed,mandriva-everytime
bootloader --location=none


# Disk setup
clearpart --initlabel --all 
part /boot/EFI --fstype=vfat --size=256  --label=efi    --asprimary --ondisk img
part /         --fstype=ext4 --size=3072 --label=rootfs --asprimary --ondisk img


# Repositories to use
repo --name=cauldron --excludepkgs=kernel-desktop* --baseurl=http://ftp.free.fr/mirrors/mageia.org/distrib/cauldron/armv7hl/media/core/release 
repo --name=cauldron-nonfree                       --baseurl=http://ftp.free.fr/mirrors/mageia.org/distrib/cauldron/armv7hl/media/nonfree/release
# Loacl containing the kernel, uboot-images, uboot-tools and bcm283x-firmware
repo --name=local_mageia_sbc                       --baseurl=file:///home/repository/mageia/cauldron/armv7hl/local

# Package setup
%packages --nocore --excludeWeakdeps 
basesystem
locales-en
uboot-images-armv7
uboot-tools
kernel
dracut
bcm283x-firmware
kernel-firmware-nonfree
grub2-efi
dhcp-client
wpa_supplicant
chrony
openssh-server
sudo
dnf
dnf-plugins-core
bash-completion
wget
nano
%end

%pre
# nothing to do
%end


%post 

## FIXME: workarounds for {uboot,efi}-boot
echo "Setting up workarounds for uboot-uefi..."

#
# The boot flag for 1st (fat32) efi-partition is set afterwards
#

# Speed-up boot a bit
# Don't probe local OS's at image-creation
cat > /etc/default/grub << EOF
GRUB_TIMEOUT=4
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_OS_PROBER="true"
EOF

## FIXME end: workarounds for efi 


## FIXME kernel install

# copy device tree
# TODO make this part of installkernel  (.. or kernel-install??)
echo "Setting up device-tree..."
kernel_version=$(echo $(basename /boot/vmlinuz-*) | sed 's/vmlinuz-//')
cp -rp /usr/lib/linux-$kernel_version/ /boot/EFI/dtb

## FIXME end: kernel install


# Uboot RPI 
cp -P /usr/share/uboot/rpi_2/u-boot.bin     /boot/EFI/rpi2-u-boot.bin
cp -P /usr/share/uboot/rpi_3_32b/u-boot.bin /boot/EFI/rpi3-u-boot.bin
cp -P /usr/share/uboot/rpi_4_32b/u-boot.bin /boot/EFI/rpi4-u-boot.bin

# FIXME : Allow ssh RootLogin in the development-stage
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config


echo "Write README file..."
cat >/root/README << EOF
== Mageia Cauldron development SBC image ==

Note: this is a community effort not supported by Magiea by any means
      it's just an "academic proof of concepts" 
      
      Please check /root/anaconda-ks.cfg on how this image came to life

      nevertheless : have fun and debug!  

EOF


# Enable heartbeat LED
echo "ledtrig-heartbeat" > /etc/modules-load.d/sbc.conf

echo "Disabeling and Masking kdump.service..."
systemctl mask kdump.service

# Remove ifcfg-link on pre generated images
rm -f /etc/sysconfig/network-scripts/ifcfg-link

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id


#FIXME : these repositories do not seem to be present 
dnf config-manager --set-disabled mageia-armv7hl updates-armv7hl


# Cleanup yum cache
dnf clean all


#Add local repo

%include ks/RPI-wifi.ks

%end

#
# Create grub-efi stub
# 
%post --nochroot
/usr/bin/mount --bind /dev $INSTALL_ROOT/dev
/usr/sbin/chroot $INSTALL_ROOT /bin/bash -c \
"/usr/sbin/grub2-install --target=arm-efi --removable --no-bootsector --no-nvram"
/usr/sbin/chroot $INSTALL_ROOT /bin/bash -c \
"/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg"
/usr/bin/umount $INSTALL_ROOT/dev
%end
