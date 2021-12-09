#
# Cookbook:: ccadi_geoserver
# Recipe:: zfs
#
# Copyright:: 2021, CCADI Project Contributors, All Rights Reserved.

# Enable EPEL repository
yum_package "epel-release"

# Install OpenZFS release for EL 7.9
remote_file "/opt/src/zfs_release.rpm" do
	source "https://zfsonlinux.org/epel/zfs-release.el7_9.noarch.rpm"
end

execute "install OpenZFS" do
	command "yum install --assumeyes /opt/src/zfs_release.rpm"
	not_if "yum list installed | grep -q 'zfs-release'"
end

# Instead of downloading the key from MIT's public servers which sometimes
# go offline, I have embedded the key into the cookbook instead.
cookbook_file "/opt/src/zfs_public_key" do
	source "zfs/public_key"
	mode "0444"
end

execute "import ZFS public key" do
	command "rpm --import /opt/src/zfs_public_key"
end

# Switch from DKMS ZFS to kABI ZFS
bash "switch ZFS configuration" do
	code <<-EOH
	yum-config-manager --disable zfs
	yum-config-manager --enable zfs-kmod
EOH
end

# Install ZFS, for real
execute "install ZFS" do
	command "yum install --assumeyes zfs"
	not_if "yum list installed | grep -q -E '^zfs\.x86_64'"
end

# Load ZFS module
file "/etc/modules-load.d/zfs.conf" do
	content "zfs"
end

execute "/sbin/modprobe zfs"
