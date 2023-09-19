FROM binhex/arch-int-vpn:latest
LABEL org.opencontainers.image.authors = "binhex"
LABEL org.opencontainers.image.source = "https://github.com/binhex/arch-sabnzbdvpn"

# additional files
##################

# add supervisor conf file for app
ADD build/*.conf /etc/supervisor/conf.d/

# add bash scripts to install app
ADD build/root/*.sh /root/

# get release tag name from build arg
arg RELEASETAG

# add run bash scripts
ADD run/nobody/*.sh /home/nobody/

# install app
#############

# make executable and run bash scripts to install app
RUN chmod +x /root/*.sh /home/nobody/*.sh && \
	/bin/bash /root/install.sh "${release_tag_name}"

# docker settings
#################

# expose port for http
EXPOSE 8080

# expose port for https
EXPOSE 8090

# set permissions
#################

# run script to set uid, gid and permissions
CMD ["/bin/bash", "/usr/local/bin/init.sh"]