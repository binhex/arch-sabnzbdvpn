#!/bin/bash

# define pacman packages
pacman_packages="python2-pyopenssl python2-feedparser"

# install pre-reqs
pacman -Sy --noconfirm
pacman -S --needed $pacman_packages --noconfirm

# call aur packer script
source /root/packer.sh

# set permissions
chown -R nobody:users /opt/sabnzbd
chmod -R 775 /opt/sabnzbd

# cleanup
yes|pacman -Scc
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /tmp/*
