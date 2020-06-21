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
bootloader --location=none --extlinux


# Disk setup
clearpart --initlabel --all 
part /boot/EFI --fstype=vfat --size=512  --label=efi    --asprimary --ondisk img
part /         --fstype=ext4 --size=2560 --label=rootfs --asprimary --ondisk img


# Repositories to use
repo --name=cauldron         --baseurl=http://ftp.free.fr/mirrors/mageia.org/distrib/cauldron/armv7hl/media/core/release
repo --name=cauldron-nonfree --baseurl=http://ftp.free.fr/mirrors/mageia.org/distrib/cauldron/armv7hl/media/nonfree/release
# Local repository  containing uboot-images-armv8, uboot-tools and bcm283x-firmware
repo --name=local_mageia_sbc  --baseurl=file:///home/repository/mageia/cauldron/local/armv7hl/Packages

# Package setup
%packages --nocore --excludeWeakdeps
basesystem
locales-en
uboot-images-armv7
uboot-tools
bcm283x-firmware
kernel-firmware-nonfree
dhcp-client
wpa_supplicant
wireless-tools
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

## FIXME kernel install

# Rewrite extlinux.conf
# Get the kernel-version as installed in /boot
# Grep rootfs UUID= from fstab created by appliance-creator
echo "Fixing extlinux.conf..." 
kernel_version=$(echo $(basename /boot/vmlinuz-*) | sed 's/vmlinuz-//')
rootfs_uuid=$(cat /etc/fstab | grep '/ ' | awk '{print $1 }')
cat > /boot/extlinux/extlinux.conf << EOF
# File generated in appliance-creator
timeout 5
menu title Welcome to Mageia

label desktop 5.7.2-1.mga8
  kernel /boot/vmlinuz-$kernel_version
  initrd /boot/initrd-$kernel_version.img
  fdtdir /usr/lib/linux-$kernel_version
  append root=$rootfs_uuid ro 

EOF

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

# Disabeling and Masking sevices
echo "Disabeling and Masking services..."
systemctl mask kdump.service
systemctl mask systemd-homed.service

# Remove ifcfg-link on pre generated images
rm -f /etc/sysconfig/network-scripts/ifcfg-link

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

#FIXME : these repositories do not seem to be present 
dnf config-manager --set-disabled mageia-armv7hl updates-armv7hl

# Cleanup yum cache
dnf clean all

%include ks/RPI-wifi.ks

%end
