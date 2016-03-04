#!/bin/bash

# exit script if return code != 0
set -e

# define aur helper
aur_helper="packer"

# define aur packages
aur_packages="sabnzbd"

# define pacman packages
pacman_packages="base-devel git"

# install required pre-reqs for makepkg
pacman -S --needed $pacman_packages --noconfirm

# create "makepkg-user" user for makepkg
useradd -m -s /bin/bash makepkg-user
echo -e "makepkg-password\nmakepkg-password" | passwd makepkg-user
echo "makepkg-user ALL=(ALL) NOPASSWD: ALL" | (EDITOR="tee -a" visudo)

# download aur helper (patched version for rpc v5)
curl -L -o "/usr/bin/$aur_helper" "https://github.com/binhex/arch-patches/raw/master/arch-packer/$aur_helper"
chmod a+x "/usr/bin/$aur_helper"
pacman -S --needed jansson expac jshon --noconfirm

# download aur helper
# curl -L -o "/home/makepkg-user/$aur_helper.tar.gz" "https://aur.archlinux.org/cgit/aur.git/snapshot/$aur_helper.tar.gz"
# cd /home/makepkg-user
# su -c "tar -xvf $aur_helper.tar.gz" - makepkg-user

# install aur helper
# su -c "cd /home/makepkg-user/$aur_helper && makepkg -s --noconfirm --needed" - makepkg-user
# pacman -U "/home/makepkg-user/$aur_helper/$aur_helper*.tar.xz" --noconfirm

# install app using aur helper
su -c "$aur_helper -S $aur_packages --noconfirm" - makepkg-user

# remove base devel excluding pacman (holdpkg)
pacman -Ru $(pacman -Qgq base-devel | grep -v pacman) --noconfirm

# remove git
pacman -Ru git --noconfirm

# remove makepkg-user account
userdel -r makepkg-user