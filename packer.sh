#!/bin/bash

# define pacman packages
pacman_packages="base-devel"

# define packer packages
packer_packages="par2cmdline-tbb sabnzbd"

# install required pre-reqs for makepkg
pacman -S --needed $pacman_packages --noconfirm

# create "makepkg-user" user for makepkg
useradd -m -g wheel -s /bin/bash makepkg-user
echo -e "makepkg-password\nmakepkg-password" | passwd makepkg-user
echo "%wheel      ALL=(ALL) ALL" >> /etc/sudoers
echo "Defaults:makepkg-user      !authenticate" >> /etc/sudoers

# download packer
curl -o /home/makepkg-user/packer.tar.gz https://aur.archlinux.org/packages/pa/packer/packer.tar.gz
cd /home/makepkg-user
tar -xvf packer.tar.gz

# install packer
su -c "cd /home/makepkg-user/packer && makepkg -s --noconfirm --needed" - makepkg-user
pacman -U /home/makepkg-user/packer/packer*.tar.xz --noconfirm

# install app from aur
su -c "packer -S sabnzbd --noconfirm" - makepkg-user

# uninstall par2cmdline
pacman -Rdd par2cmdline --noconfirm

# install multi-threaded par2cmdline
su -c "packer -S par2cmdline-tbb --noconfirm" - makepkg-user

# remove base devel tools and packer
pacman -Ru packer base-devel git --noconfirm

# delete makepkg-user account
userdel -r makepkg-user
