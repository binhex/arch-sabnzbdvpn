#!/bin/bash

# define pacman packages
pacman_packages="base-devel"

# define packer packages
packer_packages="sabnzbd"

# install required pre-reqs for makepkg
pacman -S --needed $pacman_packages --noconfirm

# create "makepkg-user" user for makepkg
useradd -m -g wheel -s /bin/bash makepkg-user
echo -e "makepkg-password\nmakepkg-password" | passwd makepkg-user
echo "%wheel      ALL=(ALL) ALL" >> /etc/sudoers
echo "Defaults:makepkg-user      !authenticate" >> /etc/sudoers

# download packer
curl -o /home/makepkg-user/packer-color.tar.gz https://aur4.archlinux.org/cgit/aur.git/snapshot/packer-color.tar.gz
cd /home/makepkg-user
su -c "tar -xvf packer-color.tar.gz" - makepkg-user

# install packer
su -c "cd /home/makepkg-user/packer-color && makepkg -s --noconfirm --needed" - makepkg-user
pacman -U /home/makepkg-user/packer-color/packer*.tar.xz --noconfirm

# install app using packer
su -c "packer-color -S $packer_packages --noconfirm" - makepkg-user

# remove base devel tools and packer
pacman -Ru packer-color base-devel git --noconfirm

# re-install sed and grep as these packages are removed when uninstalling base-devel
pacman -S --needed sed grep --noconfirm

# delete makepkg-user account
userdel -r makepkg-user
