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
part /boot/EFI --fstype=vfat --size=512  --label=efi    --asprimary --ondisk img
part /         --fstype=ext4 --size=2560 --label=rootfs --asprimary --ondisk img


# Repositories to use
repo --name=cauldron         --mirrorlist=https://www.mageia.org/mirrorlist/?release=cauldron&arch=aarch64&section=core&repo=release
repo --name=cauldron-nonfree --mirrorlist=https://www.mageia.org/mirrorlist/?release=cauldron&arch=aarch64&section=nonfree&repo=release
# Copr repo for Mageia_SBC'c owned by markvnl containing uboot-images-armv8, uboot-tools and bcm283x-firmware
repo --name=copr_mageia_sbc  --baseurl=https://download.copr.fedorainfracloud.org/results/markvnl/Mageia_aarch64_SBC-tools/mageia-cauldron-aarch64/

# Package setup
%packages --nocore --excludeWeakdeps
basesystem
locales-en
uboot-images-armv8
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

## FIXME: workarounds for aarch64 {uboot,efi}-boot
echo "Setting up workarounds for aarch64 uboot-uefi..."
#

#
# The boot flag for 1st (fat32) efi-partition is set afterwards
#

# (re)configure GRUB2, does not work (yet), 
# mounted the image on a loop device:
#   mount ${loopdev}p2 ${mountpoint}
#   mount ${loopdev}p1 ${mountpoint}/boot/EFI
#   mount --bind /proc ${mountpoint}/proc
#   mount --bind /dev  ${mountpoint}/dev
#   mount --bind /sys  ${mountpoint}/sys
#
# and ran:
#   chroot ${mountpoint} /bin/bash -c "/usr/sbin/grub2-install --target=arm64-efi --efi-directory=/boot/EFI --bootloader-id=mageia --no-bootsector --no-nvram"
#   chroot ${mountpoint} /bin/bash -c "/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg"
#

# Speed-up boot a bit
# Don't probe local OS's at image-creation
cat > /etc/default/grub << EOF
GRUB_TIMEOUT=2
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_OS_PROBER="true"
EOF


## FIXME end: workarounds for aarch64 


## FIXME kernel install

# Kernel installation fails at image creation with: (probably cause: {dev sys proc} is not mounted})
#   Running scriptlet: kernel-desktop-...  
#   Undefined subroutine &main::SYS_mknod called at /usr/share/perl5/vendor_perl/MDK/Common/System.pm line 357.  

# Get kernel_version
# TODO : why does this not work? 
#        kernel_version=$(rpm -q --queryformat '%{version}-%{release}' $(rpm -qf /boot/vmlinux-*))
kernel_version=$(echo $(ls /boot/vm*) | sed 's/\/boot\/vmlinuz-//')

# copy device tree and make link
# TODO make this part of kernelinstall  (.. or kernel-install??)
echo "Setting up device-tree..."
cp -rp /usr/lib64/linux-$kernel_version/ /boot/dtb-$kernel_version
ln -s dtb-$kernel_version /boot/dtb

# make initram_fs
echo "Creating initram_fs..."
dracut -f -N /boot/initrd-$kernel_version.img $kernel_version


## FIXME end: kernel install


# make uefi-stub
echo "Creating UEFI-stub"
grub2-install --target=arm64-efi --efi-directory=/boot/EFI --bootloader-id=mageia --no-bootsector --no-nvram --force


# Uboot RPI 
cp -P /usr/share/uboot/rpi_3/u-boot.bin /boot/EFI/rpi3-u-boot.bin
cp -P /usr/share/uboot/rpi_4/u-boot.bin /boot/EFI/rpi4-u-boot.bin


# FIXME : Allow ssh RootLogin in the development-stage
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config


echo "Write README file..."
cat >/root/README << EOF
== Mageia Cauldron development AARCH64 SBC image ==

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
dnf config-manager --set-disabled updates-aarch64 mageia-aarch64


# Cleanup yum cache
dnf clean all


# add Copr repo for Mageia_aarch64_SBC-tools owned by markvnl
cat > /etc/yum.repos.d/Copr_aarch64_SBC-tools.repo << EOF
# full name useful if yum-copr plugin is installed
# [copr:copr.fedorainfracloud.org:markvnl:Mageia_aarch64_SBC-tools]
# human readable name
[aarch64-sbc-tools]
name=Copr repo for Mageia_aarch64_SBC-tools owned by markvnl
baseurl=https://download.copr.fedorainfracloud.org/results/markvnl/Mageia_aarch64_SBC-tools/mageia-cauldron-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/markvnl/Mageia_aarch64_SBC-tools/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF


%include ks/RPI-wifi.ks


%end
