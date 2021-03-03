#!/usr/bin/bash -ex

echo ">>>> UPDATING SYSTEM PACKAGES ..."
sudo pacman -Syu --noconfirm
echo ">>> Done!"

#This step fixes corrupted PGP signatures that can cause the script to exit with error(s)
echo ">>>> REFRESHING PGP SIGNATURES ..."
sudo pacman-key --refresh-keys
echo ">>> Done!"

echo ">>>> INSTALLING XORG ..."
sudo pacman -S xorg --needed --noconfirm
echo ">>> Done!"

echo ">>>> INSTALLING DISPLAY MANAGER, GNOME desktop ..."

PKGS=(
        'gnome'                  
        'gnome-tweaks'           
        'gnome'                 
        'nautilus-sendto'               
        'gnome-nettool' 
        'gnome-usage' 
        'adwaita-icon-theme' 
        'chrome-gnome-shell'
        'xdg-user-dirs-gtk'
        'fwupd'
        'arc-gtk-theme'
        'gdm'
)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    sudo pacman -S "$PKG" --noconfirm
done

echo ">>> Done!"

echo ">>> INSTALL APPLICATIONS ..."
PKGS2=(
        'firefox'                  
        'archlinux-wallpaper'           
        'xscreensaver'                 
        'leafpad'
)

for PKG2 in "${PKGS2[@]}"; do
    echo "INSTALLING: ${PKG2}"
    sudo pacman -S "$PKG2" --needed --noconfirm
done 

echo ">>> Done!"

echo ">>> ENABLING GDM AND NetworkManager AT STARTUP ..."
sudo systemctl enable gdm
sudo systemctl enable NetworkManager
echo ">>> Done!"

echo ">>> REBOOTING ..."
sudo reboot
