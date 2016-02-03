**Application**

[SABnzbd](http://sabnzbd.org/)  
[OpenVPN](https://openvpn.net/)  
[Privoxy](http://www.privoxy.org/)

**Application description**

SABnzbd is an Open Source Binary Newsreader written in Python. It's totally free, incredibly easy to use, and works practically everywhere. SABnzbd makes Usenet as simple and streamlined as possible by automating everything we can. All you have to do is add an .nzb. This Docker includes OpenVPN to ensure a secure and private connection to the Internet, including use of iptables to prevent IP leakage when the tunnel is down. It also includes Privoxy to allow unfiltered access to index sites, to use Privoxy please point your application at `http://<host ip>:8181`.

**Build notes**

Latest stable SABnzbd release from Arch Linux AUR using Packer to compile.
Latest stable OpenVPN release from Arch Linux repo.
Latest stable Privoxy release from Arch Linux repo.

**Usage**
```
docker run -d \
	--cap-add=NET_ADMIN \
	-p 8080:8080 \
	-p 8090:8090 \
	-p 8118:8118 \
	--name=<container name> \
	-v <path for data files>:/data \
	-v <path for config files>:/config \
	-v /etc/localtime:/etc/localtime:ro \
	-e VPN_ENABLED=<yes|no> \
	-e VPN_USER=<vpn username> \
	-e VPN_PASS=<vpn password> \
	-e VPN_REMOTE=<vpn remote gateway> \
	-e VPN_PORT=<vpn remote port> \
	-e VPN_PROTOCOL=<vpn remote protocol> \
	-e VPN_PROV=<pia|airvpn|custom> \
	-e ENABLE_PRIVOXY=<yes|no> \
	-e LAN_NETWORK=<lan ipv4 network with cidr notation> \
	-e DEBUG=<true|false> \
	binhex/arch-sabnzbdvpn
```

Please replace all user variables in the above command defined by <> with the correct values.

**Access application**

`http://<host ip>:8080`

**Access Privoxy**

`http://<host ip>:8118`

**PIA provider**

PIA users will need to supply VPN_USER and VPN_PASS, optionally define VPN_REMOTE 
(list of gateways https://www.privateinternetaccess.com/pages/client-support/#signup) 
if you wish to use another remote gateway other than the Netherlands.

**PIA example**
```
docker run -d \
	--cap-add=NET_ADMIN \
	-p 8080:8080 \
	-p 8090:8090 \
	-p 8118:8118 \
	--name=sabnzbdvpn \
	-v /root/docker/data:/data \
	-v /root/docker/config:/config \
	-v /etc/localtime:/etc/localtime:ro \
	-e VPN_ENABLED=yes \
	-e VPN_USER=myusername \
	-e VPN_PASS=mypassword \
	-e VPN_REMOTE=nl.privateinternetaccess.com \
	-e VPN_PORT=1194 \
	-e VPN_PROTOCOL=udp \
	-e VPN_PROV=pia \
	-e ENABLE_PRIVOXY=yes \
	-e LAN_NETWORK=192.168.1.0/24 \
	-e DEBUG=false \
	binhex/arch-sabnzbdvpn
```

**AirVPN provider**

AirVPN users will need to generate a unique OpenVPN configuration
file by using the following link https://airvpn.org/generator/

1. Please select Linux and then choose the country you want to connect to
2. Save the ovpn file to somewhere safe
3. Start the delugevpn docker to create the folder structure
4. Stop delugevpn docker and copy the saved ovpn file to the /config/openvpn/ folder on the host
5. Start delugevpn docker
6. Check supervisor.log to make sure you are connected to the tunnel

**AirVPN example**
```
docker run -d \
	--cap-add=NET_ADMIN \
	-p 8080:8080 \
	-p 8090:8090 \
	-p 8118:8118 \
	--name=sabnzbdvpn \
	-v /root/docker/data:/data \
	-v /root/docker/config:/config \
	-v /etc/localtime:/etc/localtime:ro \
	-e VPN_ENABLED=yes \
	-e VPN_PROV=airvpn \
	-e ENABLE_PRIVOXY=yes \
	-e LAN_NETWORK=192.168.1.0/24 \
	-e DEBUG=false \
	binhex/arch-sabnzbdvpn
```

**Notes**

N/A

[Support forum](http://lime-technology.com/forum/index.php?topic=45822.0)