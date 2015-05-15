#!/bin/bash

# if vpn set to "no" then don't run openvpn
if [[ $VPN_ENABLED == "no" ]]; then

	echo "[info] VPN not enabled, skipping VPN tunnel local ip checks"

else

	echo "[info] VPN is enabled, checking VPN tunnel local ip is valid"

	# run script to check ip is valid for tun0
	source /home/nobody/checkip.sh

fi

echo "[info] All checks complete, starting SABnzbd..."

# run sabnzbd
/usr/sbin/python2 /opt/sabnzbd/SABnzbd.py --config-file /config --server 0.0.0.0:8080 --https 8090
