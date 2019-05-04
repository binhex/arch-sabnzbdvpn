#!/bin/bash

if [[ "${sabnzbd_running}" == "false" ]]; then

	echo "[info] Attempting to start SABnzbd..."

	# run SABnzbd (daemonized, non-blocking)
	/usr/sbin/python2 /opt/sabnzbd/SABnzbd.py --daemon --config-file /config --server 0.0.0.0:8080 --https 8090

	# make sure process sabnzbd DOES exist
	retry_count=30
	while true; do

		if ! pgrep -fa "sabnzbd" > /dev/null; then

			retry_count=$((retry_count-1))
			if [ "${retry_count}" -eq "0" ]; then

				echo "[warn] Wait for SABnzbd process to start aborted, too many retries"
				echo "[warn] Showing output from command before exit..."
				timeout 10 /usr/sbin/python2 /opt/sabnzbd/SABnzbd.py --console --config-file /config --server 0.0.0.0:8080 --https 8090 ; exit 1

			else

				if [[ "${DEBUG}" == "true" ]]; then
					echo "[debug] Waiting for SABnzbd process to start..."
				fi

				sleep 1s

			fi

		else

			echo "[info] SABnzbd process started"
			break

		fi

	done

	echo "[info] Waiting for SABnzbd process to start listening on port 8080..."

	while [[ $(netstat -lnt | awk "\$6 == \"LISTEN\" && \$4 ~ \".8080\"") == "" ]]; do
		sleep 0.1
	done

	echo "[info] SABnzbd process is listening on port 8080"

fi

# set sabnzbd ip to current vpn ip (used when checking for changes on next run)
sabnzbd_ip="${vpn_ip}"
