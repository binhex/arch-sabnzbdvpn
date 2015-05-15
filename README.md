SABnzbd + OpenVPN
==========================

SABnzbd - http://sabnzbd.org/
OpenVPN - https://openvpn.net/

Latest stable SABnzbd release for Arch Linux, including OpenVPN to tunnel torrent traffic securely (using iptables to block any traffic not bound for tunnel).

**Pull image**

```
docker pull binhex/arch-sabnzbdvpn
```

**Run container**

```
docker run -d --cap-add=NET_ADMIN -p 8080:8080 -p 8090:8090 --name=<container name> -v <path for data files>:/data -v <path for config files>:/config -v /etc/localtime:/etc/localtime:ro -e VPN_ENABLED=<yes|no> -e VPN_USER=<vpn username> -e VPN_PASS=<vpn password> -e VPN_REMOTE=<vpn remote gateway> -e VPN_PORT=<vpn remote port> -e VPN_PROV=<pia|airvpn|custom> binhex/arch-sabnzbdvpn
```

Please replace all user variables in the above command defined by <> with the correct values.

**Access sabnzbd**

```
http://<host ip>:8080
```

**PIA user**

PIA users will need to supply VPN_USER and VPN_PASS, optionally define VPN_REMOTE (list of gateways https://www.privateinternetaccess.com/pages/client-support/#signup) if you wish to use another remote gateway other than the Netherlands.

**Example**

```
docker run -d --cap-add=NET_ADMIN -p 8080:8080 -p 8090:8090 --name=sabnzbdvpn -v /root/docker/data:/data -v /root/docker/config:/config -v /etc/localtime:/etc/localtime:ro -e VPN_ENABLED=yes -e VPN_USER=myusername -e VPN_PASS=mypassword -e VPN_REMOTE=nl.privateinternetaccess.com -e VPN_PORT=1194 -e VPN_PROV=pia binhex/arch-sabnzbdvpn
```

**AirVPN user**

AirVPN users will need to generate a unique OpenVPN configuration file by using the following link https://airvpn.org/generator/

1. Please select Linux and then choose the country you want to connect to
2. Save the ovpn file to somewhere safe
3. Start the sabnzbdvpn docker to create the folder structure
4. Stop sabnzbdvpn docker and copy the saved ovpn file to the /config/openvpn/ folder on the host
5. Start sabnzbdvpn docker
6. Check supervisor.log to make sure you are connected to the tunnel

**Example**

```
docker run -d --cap-add=NET_ADMIN -p 8080:8080 -p 8090:8090 --name=sabnzbdvpn -v /root/docker/data:/data -v /root/docker/config:/config -v /etc/localtime:/etc/localtime:ro -e VPN_ENABLED=yes -e VPN_PROV=airvpn binhex/arch-sabnzbdvpn
```
