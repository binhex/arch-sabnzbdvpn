#!/bin/bash

# ip route
###

# split comma seperated string into list from LAN_NETWORK env variable
IFS=',' read -ra lan_network_list <<< "${LAN_NETWORK}"

# process lan networks in the list
for lan_network_item in "${lan_network_list[@]}"; do

	# strip whitespace from start and end of lan_network_item
	lan_network_item=$(echo "${lan_network_item}" | sed -e 's/^[ \t]*//')

	echo "[info] Adding ${lan_network_item} as route via docker eth0"
	ip route add "${lan_network_item}" via "${DEFAULT_GATEWAY}" dev eth0

done

echo "[info] ip route defined as follows..."
echo "--------------------"
ip route
echo "--------------------"


# setup iptables marks to allow routing of defined ports via eth0
###

if [[ "${DEBUG}" == "true" ]]; then
	echo "[debug] Modules currently loaded for kernel" ; lsmod
fi

# check kernel for tun module
lsmod | grep "tun" > /dev/null
tun_exit_code=$?

# delect if iptable mangle module present
if [[ $tun_exit_code != 0 ]]; then

	echo "[crit] 'tun' module not available, you will not be able to connect to SABnzbd or Privoxy outside of your LAN"
	echo "[info] Synology users: Please attempt to load the module by executing the following on your host:- 'insmod /lib/modules/tun.ko'"
	exit 1

fi

# check kernel for iptable_mangle module
lsmod | grep "iptable_mangle" > /dev/null
iptable_mangle_exit_code=$?

# delect if iptable mangle module present
if [[ $iptable_mangle_exit_code != 0 ]]; then

	echo "[warn] 'iptable_mangle' module not available, you will not be able to connect to SABnzbd or Privoxy outside of your LAN"
	echo "[info] unRAID users: Please attempt to load the module by executing the following on your host:- '/sbin/modprobe iptable_mangle'"
	echo "[info] Synology users: Please attempt to load the module by executing the following on your host:- 'insmod /lib/modules/iptable_mangle.ko'"

else

	echo "[info] iptable_mangle support detected, adding fwmark for tables"

	# setup route for sabnzbd webui http using set-mark to route traffic for port 8080 to eth0
	echo "8080    webui_http" >> /etc/iproute2/rt_tables
	ip rule add fwmark 1 table webui_http
	ip route add default via $DEFAULT_GATEWAY table webui_http

	# setup route for sabnzbd webui https using set-mark to route traffic for port 8090 to eth0
	echo "8090    webui_https" >> /etc/iproute2/rt_tables
	ip rule add fwmark 2 table webui_https
	ip route add default via $DEFAULT_GATEWAY table webui_https

fi

# input iptable rules
###

# set policy to drop for input
iptables -P INPUT DROP

# accept input to tunnel adapter
iptables -A INPUT -i "${VPN_DEVICE_TYPE}"0 -j ACCEPT

# accept input to/from docker containers (172.x range is internal dhcp)
iptables -A INPUT -s 172.17.0.0/16 -d 172.17.0.0/16 -j ACCEPT

# accept input to vpn gateway
iptables -A INPUT -i eth0 -p $VPN_PROTOCOL --sport $VPN_PORT -j ACCEPT

# accept input to sabnzbd webui port 8080
iptables -A INPUT -i eth0 -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 8080 -j ACCEPT

# accept input to sabnzbd webui port 8090
iptables -A INPUT -i eth0 -p tcp --dport 8090 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 8090 -j ACCEPT

# additional port list for scripts
if [[ ! -z "${ADDITIONAL_PORTS}" ]]; then

	# split comma seperated string into list from ADDITIONAL_PORTS env variable
	IFS=',' read -ra additional_port_list <<< "${ADDITIONAL_PORTS}"

	# process additional ports in the list
	for additional_port_item in "${additional_port_list[@]}"; do

		# strip whitespace from start and end of additional_port_item
		additional_port_item=$(echo "${additional_port_item}" | sed -e 's/^[ \t]*//')

		echo "[info] Adding additional incoming port ${additional_port_item} for eth0"

		# accept input to additional port for eth0
		iptables -A INPUT -i eth0 -p tcp --dport "${additional_port_item}" -j ACCEPT
		iptables -A INPUT -i eth0 -p tcp --sport "${additional_port_item}" -j ACCEPT

	done

fi

# process lan networks in the list
for lan_network_item in "${lan_network_list[@]}"; do

	# strip whitespace from start and end of lan_network_item
	lan_network_item=$(echo "${lan_network_item}" | sed -e 's/^[ \t]*//')

	# accept input to privoxy if enabled
	if [[ $ENABLE_PRIVOXY == "yes" ]]; then
		iptables -A INPUT -i eth0 -p tcp -s "${lan_network_item}" -d 172.17.0.0/16 -j ACCEPT
	fi

done

# accept input dns lookup
iptables -A INPUT -p udp --sport 53 -j ACCEPT

# accept input icmp (ping)
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

# accept input to local loopback
iptables -A INPUT -i lo -j ACCEPT

# output iptable rules
###

# set policy to drop for output
iptables -P OUTPUT DROP

# accept output from tunnel adapter
iptables -A OUTPUT -o "${VPN_DEVICE_TYPE}"0 -j ACCEPT

# accept output to/from docker containers (172.x range is internal dhcp)
iptables -A OUTPUT -s 172.17.0.0/16 -d 172.17.0.0/16 -j ACCEPT

# accept output from vpn gateway
iptables -A OUTPUT -o eth0 -p $VPN_PROTOCOL --dport $VPN_PORT -j ACCEPT

# if iptable mangle is available (kernel module) then use mark
if [[ $iptable_mangle_exit_code == 0 ]]; then

	# accept output from sabnzbd webui port 8080 - used for external access
	iptables -t mangle -A OUTPUT -p tcp --dport 8080 -j MARK --set-mark 1
	iptables -t mangle -A OUTPUT -p tcp --sport 8080 -j MARK --set-mark 1

	# accept output from sabnzbd webui port 8090 - used for external access
	iptables -t mangle -A OUTPUT -p tcp --dport 8090 -j MARK --set-mark 2
	iptables -t mangle -A OUTPUT -p tcp --sport 8090 -j MARK --set-mark 2

fi

# accept output from sabnzbd webui port 8080 - used for lan access
iptables -A OUTPUT -o eth0 -p tcp --dport 8080 -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 8080 -j ACCEPT

# accept output from sabnzbd webui port 8090 - used for lan access
iptables -A OUTPUT -o eth0 -p tcp --dport 8090 -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 8090 -j ACCEPT

# additional port list for scripts
if [[ ! -z "${ADDITIONAL_PORTS}" ]]; then

	# split comma seperated string into list from ADDITIONAL_PORTS env variable
	IFS=',' read -ra additional_port_list <<< "${ADDITIONAL_PORTS}"

	# process additional ports in the list
	for additional_port_item in "${additional_port_list[@]}"; do

		# strip whitespace from start and end of additional_port_item
		additional_port_item=$(echo "${additional_port_item}" | sed -e 's/^[ \t]*//')

		echo "[info] Adding additional outgoing port ${additional_port_item} for eth0"

		# accept output to additional port for eth0
		iptables -A OUTPUT -o eth0 -p tcp --dport "${additional_port_item}" -j ACCEPT
		iptables -A OUTPUT -o eth0 -p tcp --sport "${additional_port_item}" -j ACCEPT

	done

fi

# process lan networks in the list
for lan_network_item in "${lan_network_list[@]}"; do

	# strip whitespace from start and end of lan_network_item
	lan_network_item=$(echo "${lan_network_item}" | sed -e 's/^[ \t]*//')

	# accept output from privoxy if enabled - used for lan access
	if [[ $ENABLE_PRIVOXY == "yes" ]]; then
		iptables -A OUTPUT -o eth0 -p tcp -s 172.17.0.0/16 -d "${lan_network_item}" -j ACCEPT
	fi

done

# accept output for dns lookup
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

# accept output for icmp (ping)
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

# accept output from local loopback adapter
iptables -A OUTPUT -o lo -j ACCEPT

echo "[info] iptables defined as follows..."
echo "--------------------"
iptables -S
echo "--------------------"
