#!/bin/sh
set -eux

update_fuse_conf() {
	# Modify /etc/fuse.conf to allow "-o allow_root"
	if [ "${LIMA_CIDATA_MOUNTS}" -gt 0 ]; then
		if ! grep -q "^user_allow_other" /etc/fuse.conf; then
			echo "user_allow_other" >>/etc/fuse.conf
		fi
	fi
}

# Install minimum dependencies
if command -v apt-get >/dev/null 2>&1; then
	DEBIAN_FRONTEND=noninteractive
	export DEBIAN_FRONTEND
	if [ "${LIMA_CIDATA_MOUNTS}" -gt 0 ]; then
		if ! command -v sshfs >/dev/null 2>&1; then
			apt-get install -y sshfs
		fi
	fi
	if [ "${LIMA_CIDATA_CONTAINERD_SYSTEM}" = 1 ] || [ "${LIMA_CIDATA_CONTAINERD_USER}" = 1 ]; then
		if [ ! -e /usr/sbin/iptables ]; then
			apt-get install -y iptables
		fi
	fi
	if [ "${LIMA_CIDATA_CONTAINERD_USER}" = 1 ]; then
		if ! command -v newuidmap >/dev/null 2>&1; then
			apt-get install -y uidmap fuse3 dbus-user-session
		fi
	fi
elif command -v dnf >/dev/null 2>&1; then
	if [ "${LIMA_CIDATA_MOUNTS}" -gt 0 ]; then
		if ! command -v sshfs >/dev/null 2>&1; then
			dnf install -y fuse-sshfs
		fi
	fi
	if [ "${LIMA_CIDATA_CONTAINERD_SYSTEM}" = 1 ] || [ "${LIMA_CIDATA_CONTAINERD_USER}" = 1 ]; then
		if [ ! -e /usr/sbin/iptables ]; then
			dnf install -y iptables
		fi
	fi
	if [ "${LIMA_CIDATA_CONTAINERD_USER}" = 1 ]; then
		if ! command -v newuidmap >/dev/null 2>&1; then
			dnf install -y shadow-utils fuse3
		fi
		if [ ! -e /usr/bin/fusermount ]; then
			# Workaround for https://github.com/containerd/stargz-snapshotter/issues/340
			ln -s fusermount3 /usr/bin/fusermount
		fi
	fi
elif command -v pacman >/dev/null 2>&1; then
	if [ "${LIMA_CIDATA_MOUNTS}" -gt 0 ]; then
		if ! command -v sshfs >/dev/null 2>&1; then
			pacman -Syu --noconfirm sshfs
		fi
	fi
	# other dependencies are preinstalled on Arch Linux (https://linuximages.de/openstack/arch/)
elif command -v zypper >/dev/null 2>&1; then
	if [ "${LIMA_CIDATA_MOUNTS}" -gt 0 ]; then
		if ! command -v sshfs >/dev/null 2>&1; then
			zypper install -y sshfs
		fi
	fi
	if [ "${LIMA_CIDATA_CONTAINERD_SYSTEM}" = 1 ] || [ "${LIMA_CIDATA_CONTAINERD_USER}" = 1 ]; then
		if [ ! -e /usr/sbin/iptables ]; then
			zypper install -y iptables
		fi
	fi
	if [ "${LIMA_CIDATA_CONTAINERD_USER}" = 1 ]; then
		if ! command -v mount.fuse3 >/dev/null 2>&1; then
			zypper install -y fuse3
		fi
	fi
elif command -v apk >/dev/null 2>&1; then
	if [ "${LIMA_CIDATA_MOUNTS}" -gt 0 ]; then
		if ! command -v sshfs >/dev/null 2>&1; then
			apk update
			apk add sshfs
		fi
	fi
fi

# update_fuse_conf has to be called after installing all the packages,
# otherwise apt-get fails with conflict
update_fuse_conf
