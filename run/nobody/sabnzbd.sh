#!/bin/bash

# if vpn set to "no" then don't run openvpn
if [[ "${VPN_ENABLED}" == "no" ]]; then

	echo "[info] VPN not enabled, skipping VPN tunnel local ip checks"

	# run sabnzbd (non daemonized, blocking)
	echo "[info] Attempting to start SABnzbd..."
	/usr/sbin/python2 /opt/sabnzbd/SABnzbd.py --config-file /config --server 0.0.0.0:8080 --https 8090

else

	echo "[info] VPN is enabled, checking VPN tunnel local ip is valid"

	# set triggers to first run
	sabnzbd_running="false"

	# while loop to check ip
	while true; do

		# run script to check ip is valid for tunnel device (will block until valid)
		source /home/nobody/getvpnip.sh

		# if vpn_ip is not blank then run, otherwise log warning
		if [[ ! -z "${vpn_ip}" ]]; then

			# check if sabnzbd is running, if not then skip reconfigure for ip
			if ! pgrep -x python2 > /dev/null; then

				echo "[info] SABnzbd not running"

				# mark as sabnzbd not running
				sabnzbd_running="false"

			else

				# if sabnzbd is running, then reconfigure ip
				sabnzbd_running="true"

			fi

			if [[ "${sabnzbd_running}" == "false" ]]; then

				echo "[info] Attempting to start SABnzbd..."

				# run sabnzbd (daemonized, non-blocking)
				/usr/sbin/python2 /opt/sabnzbd/SABnzbd.py --daemon --config-file /config --server 0.0.0.0:8080 --https 8090

				echo "[info] SABnzbd started"

			fi

			# reset triggers to negative values
			sabnzbd_running="false"

			if [[ "${DEBUG}" == "true" ]]; then

				echo "[debug] VPN IP is ${vpn_ip}"

			fi

		else

			echo "[warn] VPN IP not detected, VPN tunnel maybe down"

		fi

		sleep 30s

	done

fi
