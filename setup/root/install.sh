#!/bin/bash

# exit script if return code != 0
set -e

# define pacman packages
pacman_packages="base-devel git python2-pyopenssl python2-feedparser p7zip"

# install pre-reqs
pacman -S --needed $pacman_packages --noconfirm

# call aur script (arch user repo)
source /root/aur.sh

# create file with contets of here doc
cat <<'EOF' > /tmp/additional_ports_heredoc
        export ADDITIONAL_PORTS=$(echo "${ADDITIONAL_PORTS}" | sed -e 's/^[ \t]*//')
        if [[ ! -z "${ADDITIONAL_PORTS}" ]]; then
                echo "[info] ADDITIONAL_PORTS defined as '${ADDITIONAL_PORTS}'" | ts '%Y-%m-%d %H:%M:%.S'
        else
                echo "[info] ADDITIONAL_PORTS not defined (via -e ADDITIONAL_PORTS), skipping allow for custom incoming ports" | ts '%Y-%m-%d %H:%M:%.S'
        fi
EOF

# replace placeholder string with contents of file (here doc)
sed -i '/# ADDITIONAL_PORTS_PLACEHOLDER/{
    s/# ADDITIONAL_PORTS_PLACEHOLDER//g
    r /tmp/additional_ports_heredoc
}' /root/init.sh

rm /tmp/additional_ports_heredoc

# append here doc to file
cat <<EOF >> /root/init.sh
# set permissions inside container
chown -R "${PUID}":"${PGID}" /opt/sabnzbd /usr/bin/privoxy /etc/privoxy /home/nobody
chmod -R 775 /opt/sabnzbd /usr/bin/privoxy /etc/privoxy /home/nobody

echo "[info] Starting Supervisor..."

# run supervisor
exec /usr/bin/supervisord -c /etc/supervisor.conf -n
EOF

# cleanup
yes|pacman -Scc
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /tmp/*
