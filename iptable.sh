#!/bin/bash

# setup route for sabnzbd http webui using set-mark to route traffic for port 8080 to eth0
echo "8080    webui_http" >> /etc/iproute2/rt_tables
ip rule add fwmark 1 table webui_http
ip route add default via $DEFAULT_GATEWAY table webui_http

# setup route for sabnzbd https webui using set-mark to route traffic for port 8090 to eth0
echo "8090    webui_https" >> /etc/iproute2/rt_tables
ip rule add fwmark 2 table webui_https
ip route add default via $DEFAULT_GATEWAY table webui_https

# setup route for privoxy using set-mark to route traffic for port 8118 to eth0
if [[ $ENABLE_PRIVOXY == "yes" ]]; then
	echo "8118    privoxy" >> /etc/iproute2/rt_tables
	ip rule add fwmark 3 table privoxy
	ip route add default via $DEFAULT_GATEWAY table privoxy
fi

echo "[info] ip routing table"
ip route
echo "--------------------"

# input iptable rules
###

# set policy to drop for input
iptables -P INPUT DROP

# accept input to tunnel adapter
iptables -A INPUT -i tun0 -j ACCEPT

# accept input to vpn gateway
iptables -A INPUT -i eth0 -p $VPN_PROTOCOL --sport $VPN_PORT -j ACCEPT

# accept input to sabnzbd webui port 8080
iptables -A INPUT -i eth0 -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 8080 -j ACCEPT

# accept input to privoxy port 8090
iptables -A INPUT -i eth0 -p tcp --dport 8090 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 8090 -j ACCEPT

# accept input to privoxy port 8118 if enabled
if [[ $ENABLE_PRIVOXY == "yes" ]]; then
	iptables -A INPUT -i eth0 -p tcp --dport 8118 -j ACCEPT
	iptables -A INPUT -i eth0 -p tcp --sport 8118 -j ACCEPT
fi

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

# accept output to tunnel adapter
iptables -A OUTPUT -o tun0 -j ACCEPT

# accept output to vpn gateway
iptables -A OUTPUT -o eth0 -p $VPN_PROTOCOL --dport $VPN_PORT -j ACCEPT

# accept output to sabnzbd webui port 8080 (used when tunnel down)
iptables -A OUTPUT -o eth0 -p tcp --dport 8080 -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 8080 -j ACCEPT

# accept output to sabnzbd http webui port 8080 (used when tunnel up)
iptables -t mangle -A OUTPUT -p tcp --dport 8080 -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -p tcp --sport 8080 -j MARK --set-mark 1

# accept output to sabnzbd https webui port 8090 (used when tunnel up)
iptables -t mangle -A OUTPUT -p tcp --dport 8090 -j MARK --set-mark 2
iptables -t mangle -A OUTPUT -p tcp --sport 8090 -j MARK --set-mark 2

# accept output to privoxy port 8118 if enabled
if [[ $ENABLE_PRIVOXY == "yes" ]]; then
	iptables -t mangle -A OUTPUT -p tcp --dport 8118 -j MARK --set-mark 3
	iptables -t mangle -A OUTPUT -p tcp --sport 8118 -j MARK --set-mark 3
fi

# accept output dns lookup
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

# accept output icmp (ping)
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

# accept output to local loopback
iptables -A OUTPUT -o lo -j ACCEPT

echo "[info] iptables"
iptables -S
echo "--------------------"

# add in google public nameservers (isp may block ns lookup when connected to vpn)
echo 'nameserver 8.8.8.8' > /etc/resolv.conf
echo 'nameserver 8.8.4.4' >> /etc/resolv.conf

echo "[info] nameservers"
cat /etc/resolv.conf
echo "--------------------"

# start openvpn tunnel
source /root/openvpn.sh
