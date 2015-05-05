#!/bin/bash

# run script to check ip is valid for tun0
source /home/nobody/checkip.sh

echo "[info] Starting SABnzbd..."

# run sabnzbd
/usr/sbin/python2 /opt/sabnzbd/SABnzbd.py --config-file /config --server 0.0.0.0:8080 --https 8090
