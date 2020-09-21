#!/bin/bash

if [[ "${sabnzbd_running}" == "false" ]]; then

	echo "[info] Attempting to start SABnzbd..."

	# run SABnzbd (daemonized, non-blocking)
	/usr/sbin/python3 /usr/lib/sabnzbd/SABnzbd.py --daemon --config-file /config --server 0.0.0.0:8080 --https 8090

	# make sure process sabnzbd DOES exist
	retry_count=12
	retry_wait=1
	while true; do

		if ! pgrep -fa "sabnzbd" > /dev/null; then

			retry_count=$((retry_count-1))
			if [ "${retry_count}" -eq "0" ]; then

				echo "[warn] Wait for SABnzbd process to start aborted, too many retries"
				echo "[info] Showing output from command before exit..."
				timeout 10 /usr/sbin/python3 /usr/lib/sabnzbd/SABnzbd.py --console --config-file /config --server 0.0.0.0:8080 --https 8090 ; return 1

			else

				if [[ "${DEBUG}" == "true" ]]; then
					echo "[debug] Waiting for rTorrent process to start"
					echo "[debug] Re-check in ${retry_wait} secs..."
					echo "[debug] ${retry_count} retries left"
				fi
				sleep "${retry_wait}s"

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
