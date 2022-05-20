#!/usr/bin/env bash

# stop on errors
set -eu

if [[ $PACKER_BUILDER_TYPE == "qemu" ]]; then
  DISK='/dev/vda'
else
  DISK='/dev/sda'
fi

FQDN='vagrant-arch.vagrantup.com'
KEYMAP='us'
LANGUAGE='en_US.UTF-8'
PASSWORD=$(/usr/bin/openssl passwd -crypt 'vagrant')
TIMEZONE='UTC'

CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'
ROOT_PARTITION="${DISK}2"
TARGET_DIR='/mnt'

echo ">>>> install-base.sh: Clearing partition table on ${DISK}.."
/usr/bin/sgdisk --zap ${DISK}

echo ">>>> install-base.sh: Destroying magic strings and signatures on ${DISK}.."
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
/usr/bin/wipefs --all ${DISK}

echo ">>>> install-base.sh: Creating grub partition on ${DISK}.."
/usr/bin/sgdisk -n 0:0:+1MiB -t 0:ef02 -c 0:grub ${DISK}

echo ">>>> install-base.sh: Creating /root partition on ${DISK}.."
/usr/bin/sgdisk -n 0:0:0 -t 0:8300 -c 0:root ${DISK}

echo ">>>> install-base.sh: Creating /root filesystem (ext4).."
/usr/bin/mkfs.ext4 -O ^64bit -F -m 0 -q -L root ${ROOT_PARTITION}

echo ">>>> install-base.sh: Mounting ${ROOT_PARTITION} to ${TARGET_DIR}.."
/usr/bin/mount -o noatime,errors=remount-ro ${ROOT_PARTITION} ${TARGET_DIR}

echo ">>>> install-base.sh: Setting up latest and fastest pacman mirrors.."
reflector --latest 7 --sort rate --download-timeout 47 --save /etc/pacman.d/mirrorlist

echo ">>>> install-base.sh: Bootstrapping the base installation.."
/usr/bin/pacstrap ${TARGET_DIR} base base-devel linux
#/usr/bin/pacstrap ${TARGET_DIR} base linux

# Need to install netctl as well: https://github.com/archlinux/arch-boxes/issues/70
# Can be removed when Vagrant's Arch plugin will use systemd-networkd: https://github.com/hashicorp/vagrant/pull/11400
echo ">>>> install-base.sh: Installing basic packages.."
/usr/bin/arch-chroot ${TARGET_DIR} pacman -S --noconfirm gptfdisk openssh syslinux dhcpcd netctl

echo ">>>> install-base.sh: Configuring syslinux.."
/usr/bin/arch-chroot ${TARGET_DIR} syslinux-install_update -i -a -m
/usr/bin/sed -i "s|sda3|${ROOT_PARTITION##/dev/}|" "${TARGET_DIR}/boot/syslinux/syslinux.cfg"
/usr/bin/sed -i 's/TIMEOUT 50/TIMEOUT 10/' "${TARGET_DIR}/boot/syslinux/syslinux.cfg"

echo ">>>> install-base.sh: Generating the filesystem table.."
/usr/bin/genfstab -p ${TARGET_DIR} >>"${TARGET_DIR}/etc/fstab"

echo ">>>> install-base.sh: Generating the system configuration script.."
/usr/bin/install --mode=0755 /dev/null "${TARGET_DIR}${CONFIG_SCRIPT}"

CONFIG_SCRIPT_SHORT=$(basename "$CONFIG_SCRIPT")
cat <<-EOF >"${TARGET_DIR}${CONFIG_SCRIPT}"
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring hostname, timezone, and keymap.."
  echo '${FQDN}' > /etc/hostname
  /usr/bin/ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
  echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring locale.."
  /usr/bin/sed -i 's/#${LANGUAGE}/${LANGUAGE}/' /etc/locale.gen
  /usr/bin/locale-gen
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Creating initramfs.."
  /usr/bin/mkinitcpio -p linux
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Setting root pasword.."
  /usr/bin/usermod --password ${PASSWORD} root
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring network.."
  # Disable systemd Predictable Network Interface Names and revert to traditional interface names
  # https://wiki.archlinux.org/index.php/Network_configuration#Revert_to_traditional_interface_names
  /usr/bin/ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
  /usr/bin/systemctl enable dhcpcd@eth0.service
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring sshd.."
  /usr/bin/sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
  /usr/bin/systemctl enable sshd.service

  # Workaround for https://bugs.archlinux.org/task/58355 which prevents sshd to accept connections after reboot
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Adding workaround for sshd connection issue after reboot.."
  /usr/bin/pacman -S --noconfirm rng-tools
  /usr/bin/systemctl enable rngd

  # Vagrant-specific configuration
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Creating vagrant user.."
  /usr/bin/useradd --password ${PASSWORD} --comment 'Vagrant User' --create-home --user-group vagrant
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring sudo.."
  echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_vagrant
  echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_vagrant
  /usr/bin/chmod 0440 /etc/sudoers.d/10_vagrant
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring ssh access for vagrant.."
  /usr/bin/install --directory --owner=vagrant --group=vagrant --mode=0700 /home/vagrant/.ssh
  /usr/bin/curl --output /home/vagrant/.ssh/authorized_keys --location https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
  /usr/bin/chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
  /usr/bin/chmod 0600 /home/vagrant/.ssh/authorized_keys

  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Cleaning up.."
  /usr/bin/pacman -Rcns --noconfirm gptfdisk
EOF

echo ">>>> install-base.sh: Entering chroot and configuring system.."
/usr/bin/arch-chroot ${TARGET_DIR} ${CONFIG_SCRIPT}
rm "${TARGET_DIR}${CONFIG_SCRIPT}"

# http://comments.gmane.org/gmane.linux.arch.general/48739
echo ">>>> install-base.sh: Adding workaround for shutdown race condition.."
/usr/bin/install --mode=0644 /root/poweroff.timer "${TARGET_DIR}/etc/systemd/system/poweroff.timer"


echo '==> Turning off password expiry'
sudo sed -i '/password   include      system-local-login/c\#password   include      system-local-login' /mnt/etc/pam.d/login
PASSWD=$(echo "vagrant"|openssl passwd -6 -stdin)
sudo sed -i "/root.*\:$/c\root:$PASSWD:::::::" /mnt/etc/shadow
PASSWD=$(echo "vagrant"|openssl passwd -6 -stdin)
sudo sed -i "/vagrant.*\:$/c\vagrant:$PASSWD:::::::" /mnt/etc/shadow

echo 'checking if it is vmware'
if [[ $(hostnamectl) == *"vmware"* ]]; then
   echo ">>>> configuring static ip address for network interface eth0"
   addr=$(ip route get 1.2.3.4 | awk '{print $7}')
   addr="Address=('"${addr}/24"')"
   gat=$(ip route get 1.2.3.4 | awk '{print $3}')
   gat="Gateway=('"${gat}"')"
   echo -e "Interface=eth0\nConnection=ethernet\nIP=static\n${addr}\n${gat}\nDNS=('8.8.8.8' '8.8.4.4')" > ${TARGET_DIR}/etc/netctl/eth0
   /usr/bin/arch-chroot ${TARGET_DIR}   netctl enable eth0
fi

echo ">>>> install-base.sh: Completing installation.."
/usr/bin/sleep 3
/usr/bin/umount ${TARGET_DIR}

# Turning network interfaces down to make sure SSH session was dropped on host.
# More info at: https://www.packer.io/docs/provisioners/shell.html#handling-reboots

sudo pacman -Sy --noconfirm  net-tools

echo '==> Turning down network interfaces and rebooting'
for i in $(/usr/bin/netstat -i | /usr/bin/tail +3 | /usr/bin/awk '{print $1}'); do /usr/bin/ip link set "${i}" down; done
/usr/bin/sleep 13
/usr/bin/systemctl reboot
echo ">>>> install-base.sh: Installation complete!"
