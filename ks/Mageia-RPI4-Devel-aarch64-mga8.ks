# Basic setup information
install
keyboard us
lang en_US.UTF-8
rootpw mageia
timezone UTC
selinux    --disabled
firewall   --disabled
# On Raspberry PI's we are pretty sure know the device names
network    --bootproto=dhcp --device=eth0  --activate --onboot=on
#
# TODO : Figure out {systemd-homed, mandriva-everytime}.service
services   --enabled=sshd,chronyd,zram-swap --disabled=systemd-homed,mandriva-everytime
bootloader --location=none


# Disk setup
clearpart   --initlabel --all
part /boot  --fstype=vfat --size=512  --label=boot   --asprimary --ondisk=img
part /      --fstype=ext4 --size=2048 --label=rootfs --asprimary --ondisk=img


# Repositories to use
repo --name=cauldron         --mirrorlist=https://www.mageia.org/mirrorlist/?release=cauldron&arch=$basearch&section=core&repo=release
repo --name=cauldron-nonfree --mirrorlist=https://www.mageia.org/mirrorlist/?release=cauldron&arch=aarch64&section=nonfree&repo=release
# Copr repo for Raspberry_PI4 owned by markvnl conaining the kernel and zram
repo --name=copr_rpi4        --baseurl=https://download.copr.fedorainfracloud.org/results/markvnl/Raspberry_PI4/mageia-cauldron-$basearch/

# Package setup
%packages --nocore --excludeWeakdeps
basesystem
locales-en
raspberrypi-kernel4
raspberrypi-firmware
kernel-firmware-nonfree
zram
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

# Specific cmdline.txt files needed for raspberrypi
echo "Write cmdline.txt..."
cat > /boot/cmdline.txt << EOF
console=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait
EOF


# On a PI we are pretty sure wireless network interface defaults to wlan0
# Configure wpa_supplicant to control wlan0
echo "Configuring wpa_supplicant..."
sed -i 's/INTERFACES=""/INTERFACES="-iwlan0"/' /etc/sysconfig/wpa_supplicant


# FIXME : Allow ssh RootLogin in the development-stage
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config


# cpu_governor.service
echo "Applying cpu governor fix..."
cat > /etc/systemd/system/cpu_governor.service << EOF
# FIXME raspberrypi-kernel(4) defaults to conservative governor

[Unit]
Description=Set cpu governor to ondemand

[Service]
Type=oneshot
ExecStart=/bin/sh -c " echo ondemand > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"

[Install]
WantedBy=multi-user.target
EOF

systemctl enable cpu_governor.service


# Add Copr repo for Raspberry_PI4 owned by markvnl
cat > /etc/yum.repos.d/copr_Raspberry_PI4.repo << EOF
# full name useful if dnf-copr plugin is installed
# [copr:copr.fedorainfracloud.org:markvnl:Raspberry_PI4]
# human readable name
[copr_kernel]
name=Copr repo for Raspberry_PI4 owned by markvnl
baseurl=https://download.copr.fedorainfracloud.org/results/markvnl/Raspberry_PI4/mageia-cauldron-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/markvnl/Raspberry_PI4/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF


# Remove ifcfg-link on pre generated images
rm -f /etc/sysconfig/network-scripts/ifcfg-link

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id


#FIXME : these repositories do not seem to be present 
dnf config-manager --set-disabled updates-aarch64 mageia-aarch64

# Cleanup yum cache
dnf clean all

#TODO Figure out setting for latest firmware
#%include ks/RPI-wifi.ks
#


%end
