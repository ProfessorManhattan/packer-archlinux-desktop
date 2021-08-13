#!/usr/bin/env bash

# stop on errors
set -eu

if [[ $PACKER_BUILDER_TYPE == "qemu" ]]; then
  DISK='/dev/vda'
else
  DISK='/dev/sda'
fi

sudo pacman -Sy grub --noconfirm
sudo grub-install --target=i386-pc ${DISK}
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/c\GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' /etc/default/grub
sudo sed -i -e '6aGRUB_DISABLE_OS_PROBER=false' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg