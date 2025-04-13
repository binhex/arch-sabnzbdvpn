#!/bin/bash

# exit script if return code != 0
set -e

# release tag name from buildx arg, stripped of build ver using string manipulation
RELEASETAG="${1}"

# target arch from buildx arg
TARGETARCH="${2}"

if [[ -z "${RELEASETAG}" ]]; then
	echo "[warn] Release tag name from build arg is empty, exiting script..."
	exit 1
fi

if [[ -z "${TARGETARCH}" ]]; then
	echo "[warn] Target architecture name from build arg is empty, exiting script..."
	exit 1
fi

# write RELEASETAG to file to record the release tag used to build the image
echo "IMAGE_RELEASE_TAG=${RELEASETAG}" >> '/etc/image-release'

# note do NOT download build scripts - inherited from int script with envvars common defined


# pacman packages
####

# call pacman db and package updater script
source upd.sh

# check arch as par2cmdline-turbo does not support arm64, thus use par2cmdline
if [[ "${TARGETARCH}" == "arm64" ]]; then
	par2cmdline="par2cmdline"
else
	par2cmdline=""
fi

# define pacman packages
pacman_packages="git python python-pyopenssl unrar unzip ${par2cmdline}"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aur packages
####

# check arch as par2cmdline-turbo does not support arm64
if [[ "${TARGETARCH}" == "arm64" ]]; then
	aur_packages=""
else
	# define aur packages
	aur_packages="par2cmdline-turbo"
fi

# call aur install script (arch user repo)
source aur.sh

# github
####

install_path_sabnzbd="/usr/lib/sabnzbd"

# download latest release from github for app, grabbing particular asset as source.zip does not include locale
github.sh --install-path "${install_path_sabnzbd}" --github-owner 'sabnzbd' --github-repo 'sabnzbd' --download-assets 'SABnzbd.*src.tar.gz' --strip-components '1' --query-type 'release'

install_path_nzbnotify="/usr/lib/nzbnotify"

# download latest commit from master branch for app
github.sh --install-path "${install_path_nzbnotify}" --github-owner 'caronc' --github-repo 'nzb-notify' --query-type 'branch' --download-branch 'master'

# python
####

virtualenv_path="${install_path_sabnzbd}/venv"

# use pip to install requirements for sabnzbd as defined in requirements.txt
python.sh --requirements-path "${install_path_sabnzbd}" --create-virtualenv 'yes' --virtualenv-path "${virtualenv_path}"

# use pip to install requirements for nzbnotify as defined in requirements.txt, create modules in sabnz\bd virtualenv path
python.sh --requirements-path "${install_path_nzbnotify}" --create-virtualenv 'yes' --virtualenv-path "${virtualenv_path}"

# custom
####

# required as there is no arm64 package for 7zip at present 2025-04-13
if [[ "${TARGETARCH}" == "arm64" ]]; then
	curl -o /tmp/7zip.tar.xz -L https://www.7-zip.org/a/7z2409-linux-arm64.tar.xz
else
	curl -o /tmp/7zip.tar.xz -L https://www.7-zip.org/a/7z2409-linux-x64.tar.xz
fi

# extract, remove tar file and move to /usr/bin
tar -xvf /tmp/7zip.tar.xz -C /tmp
rm /tmp/7zip.tar.xz
mv /tmp/7zzs /usr/bin/7z
chmod +x /usr/bin/7z

# container perms
####

# define comma separated list of paths
install_paths="/usr/lib/sabnzbd,/usr/lib/nzbnotify,/home/nobody"

# split comma separated string into list for install paths
IFS=',' read -ra install_paths_list <<< "${install_paths}"

# process install paths in the list
for i in "${install_paths_list[@]}"; do

	# confirm path(s) exist, if not then exit
	if [[ ! -d "${i}" ]]; then
		echo "[crit] Path '${i}' does not exist, exiting build process..." ; exit 1
	fi

done

# convert comma separated string of install paths to space separated, required for chmod/chown processing
install_paths=$(echo "${install_paths}" | tr ',' ' ')

# set permissions for container during build - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
chmod -R 775 ${install_paths}

# create file with contents of here doc, note EOF is NOT quoted to allow us to expand current variable 'install_paths'
# we use escaping to prevent variable expansion for PUID and PGID, as we want these expanded at runtime of init.sh
cat <<EOF > /tmp/permissions_heredoc

# get previous puid/pgid (if first run then will be empty string)
previous_puid=\$(cat "/root/puid" 2>/dev/null || true)
previous_pgid=\$(cat "/root/pgid" 2>/dev/null || true)

# if first run (no puid or pgid files in /tmp) or the PUID or PGID env vars are different
# from the previous run then re-apply chown with current PUID and PGID values.
if [[ ! -f "/root/puid" || ! -f "/root/pgid" || "\${previous_puid}" != "\${PUID}" || "\${previous_pgid}" != "\${PGID}" ]]; then

	# set permissions inside container - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
	chown -R "\${PUID}":"\${PGID}" ${install_paths}

fi

# write out current PUID and PGID to files in /root (used to compare on next run)
echo "\${PUID}" > /root/puid
echo "\${PGID}" > /root/pgid

EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
    s/# PERMISSIONS_PLACEHOLDER//g
    r /tmp/permissions_heredoc
}' /usr/local/bin/init.sh
rm /tmp/permissions_heredoc

# env vars
####

cat <<'EOF' > /tmp/envvars_heredoc

export APPLICATION="sabnzbd"

EOF

# replace env vars placeholder string with contents of file (here doc)
sed -i '/# ENVVARS_PLACEHOLDER/{
    s/# ENVVARS_PLACEHOLDER//g
    r /tmp/envvars_heredoc
}' /usr/local/bin/init.sh
rm /tmp/envvars_heredoc

# cleanup
cleanup.sh
