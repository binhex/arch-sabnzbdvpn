#!/bin/bash

# if vpn set to "no" then don't run openvpn
if [[ $VPN_ENABLED == "no" ]]; then

	echo "[info] VPN not enabled, skipping VPN tunnel local ip checks"

	# run sabnzbd daemon (non daemonized, blocking)
	echo "[info] All checks complete, starting SABnzbd..."
	/usr/sbin/python2 /opt/sabnzbd/SABnzbd.py --config-file /config --server 0.0.0.0:8080 --https 8090
	
else

	echo "[info] VPN is enabled, checking VPN tunnel local ip is valid"

	# run script to check ip is valid for tun0
	source /home/nobody/checkip.sh

	# set triggers to first run
	first_run="true"

	# set sleep period for recheck (in mins)
	sleep_period="10"

	# while loop to check ip and port
	while true; do

		# run scripts to identity vpn ip
		source /home/nobody/getvpnip.sh

		# if vpn_ip is not blank then run, otherwise log warning
		if [[ ! -z "${vpn_ip}" ]]; then

			# check sabnzbd is running, if not then set to first_run and reload
			if ! pgrep sabnzbd > /dev/null; then

				echo "[info] SABnzbd daemon not running, marking as first run"

				# mark as first run and reload required due to sabnzbd not running
				first_run="true"

			fi

			if [[ $first_run == "true" ]]; then

				echo "[info] All checks complete, starting SABnzbd..."

				# run sabnzbd daemon (daemonized, non-blocking)
				/usr/sbin/python2 /opt/sabnzbd/SABnzbd.py --daemon --config-file /config --server 0.0.0.0:8080 --https 8090

			fi

			# reset triggers to negative values
			first_run="false"

			if [[ "${DEBUG}" == "true" ]]; then

				echo "[debug] VPN IP is $vpn_ip"

			fi

		else

			echo "[warn] VPN IP not detected"

		fi

		if [[ "${DEBUG}" == "true" ]]; then

			echo "[debug] Sleeping for ${sleep_period} mins before rechecking"

		fi

		sleep "${sleep_period}"m

	done

fi
