#!/usr/bin/env bash

# stop on errors
set -eu
sudo pacman -Sy --noconfirm git
 runuser -l vagrant -c 'git clone https://aur.archlinux.org/plymouth.git'
  cd plymouth/
   runuser -u vagrant -- makepkg -s --noconfirm

  sudo pacman -U $(find -name '*.pkg.tar.zst') --noconfirm


sudo sed -i '/^#/! s/HOOKS=(base udev\(.*\))$/HOOKS=(base udev plymouth\1)/' /etc/mkinitcpio.conf
echo ">>> REBOOTING ..."
sudo reboot
