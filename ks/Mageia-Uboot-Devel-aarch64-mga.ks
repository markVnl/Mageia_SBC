
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
cp -rp /usr/lib64/linux-$kernel_version/ /boot/EFI/dtb

# Kernel installation fails at image creation with: (probably cause: {dev sys proc} is not mounted})
#   Running scriptlet: kernel-desktop-...  
#   Undefined subroutine &main::SYS_mknod called at /usr/share/perl5/vendor_perl/MDK/Common/System.pm line 357.  

# make initram_fs
echo "Creating initram_fs..."
dracut -q -f -N /boot/initrd-$kernel_version.img $kernel_version

## FIXME end: kernel install


# Uboot RPI 
cp -P /usr/share/uboot/rpi_3/u-boot.bin /boot/EFI/rpi3-u-boot.bin
cp -P /usr/share/uboot/rpi_4/u-boot.bin /boot/EFI/rpi4-u-boot.bin

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

#
# Create grub-efi stub
# 
%post --nochroot
/usr/bin/mount --bind /dev $INSTALL_ROOT/dev
/usr/sbin/chroot $INSTALL_ROOT /bin/bash -c \
"/usr/sbin/grub2-install --target=arm64-efi --removable --no-bootsector --no-nvram"
/usr/sbin/chroot $INSTALL_ROOT /bin/bash -c \
"/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg"
/usr/bin/umount $INSTALL_ROOT/dev
%end
