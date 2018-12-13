#!/bin/bash

# while loop to check ip and port
while true; do

	# reset triggers to negative values
	sabnzbd_running="false"
	ip_change="false"

	if [[ "${VPN_ENABLED}" == "yes" ]]; then

		# run script to check ip is valid for tunnel device (will block until valid)
		source /home/nobody/getvpnip.sh

		# if vpn_ip is not blank then run, otherwise log warning
		if [[ ! -z "${vpn_ip}" ]]; then

			# check if sabnzbd is running, if not then skip shutdown of process
			if ! pgrep -fa "sabnzbd" > /dev/null; then

				echo "[info] SABnzbd not running"

			else

				echo "[info] SABnzbd running"

				# mark as sabnzbd as running
				sabnzbd_running="true"

			fi

			if [[ "${sabnzbd_running}" == "false" ]]; then

				# run script to start sabnzbd
				source /home/nobody/sabnzbd.sh

			fi

		else

			echo "[warn] VPN IP not detected, VPN tunnel maybe down"

		fi

	else

		# check if sabnzbd is running, if not then start via sabnzbd.sh
		if ! pgrep -fa "sabnzbd" > /dev/null; then

			echo "[info] SABnzbd not running"

			# run script to start sabnzbd
			source /home/nobody/sabnzbd.sh

		fi

	fi

	if [[ "${DEBUG}" == "true" && "${VPN_ENABLED}" == "yes" ]]; then
		echo "[debug] VPN IP is ${vpn_ip}"
	fi

	sleep 30s

done
