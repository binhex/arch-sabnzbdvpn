#!/bin/bash

# if vpn set to "no" then don't run openvpn
if [[ $VPN_ENABLED == "no" ]]; then

	echo "[info] VPN not enabled, skipping VPN tunnel local ip checks"

	# run sabnzbd daemon
	echo "[info] All checks complete, starting SABnzbd..."
	/usr/sbin/python2 /opt/sabnzbd/SABnzbd.py --config-file /config --server 0.0.0.0:8080 --https 8090
	
else

	echo "[info] VPN is enabled, checking VPN tunnel local ip is valid"

	# create pia client id (randomly generated)
	client_id=`head -n 100 /dev/urandom | md5sum | tr -d " -"`

	# run script to check ip is valid for tun0
	source /home/nobody/checkip.sh

	# set triggers to first run
	first_run="true"
	reload="false"

	# set empty values for port and ip
	sabnzbd_ip=""

	# set sleep period for recheck (in mins)
	sleep_period="5"

	# while loop to check ip and port
	while true; do

		# run scripts to identity vpn ip
		source /home/nobody/getvpnip.sh

		if [[ $first_run == "false" ]]; then

			# if current bind interface ip is different to tunnel local ip then re-configure sabnzbd
			if [[ $sabnzbd_ip != "$vpn_ip" ]]; then

				echo "[info] SABnzbd listening interface IP $sabnzbd_ip and VPN provider IP different, reconfiguring for VPN provider IP $vpn_ip"

				# mark as reload required due to mismatch
				sabnzbd_ip="${vpn_ip}"
				reload="true"

			else

				echo "[info] SABnzbd listening interface IP $sabnzbd_ip and VPN provider IP $vpn_ip match"

			fi

		else

			echo "[info] First run detected, setting SABnzbd listening interface $vpn_ip"

			# mark as reload required due to first run
			sabnzbd_ip="${vpn_ip}"
			reload="true"

		fi

		if [[ $reload == "true" ]]; then

			echo "[info] All checks complete, starting SABnzbd..."

			# run sabnzbd
			/usr/sbin/python2 /opt/sabnzbd/SABnzbd.py --daemon --config-file /config --server 0.0.0.0:8080 --https 8090

		fi

		# reset triggers to negative values
		first_run="false"
		reload="false"

		echo "[info] Sleeping for ${sleep_period} mins before rechecking listen interface"
		sleep "${sleep_period}"m

	done

fi
