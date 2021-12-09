#
# Cookbook:: ccadi_geoserver
# Recipe:: zfs
#
# Copyright:: 2021, CCADI Project Contributors, All Rights Reserved.

src_dir = node["ccadi_geoserver"]["source_path"]

# Enable EPEL repository
yum_package "epel-release"

# Install OpenZFS release for EL 7.9
remote_file "#{src_dir}/zfs_release.rpm" do
	source "https://zfsonlinux.org/epel/zfs-release.el7_9.noarch.rpm"
end

execute "install OpenZFS" do
	command "yum install --assumeyes #{src_dir}/zfs_release.rpm"
	not_if "yum list installed | grep -q 'zfs-release'"
end

# Instead of downloading the key from MIT's public servers which sometimes
# go offline, I have embedded the key into the cookbook instead.
cookbook_file "#{src_dir}/zfs_public_key" do
	source "zfs/public_key"
	mode "0444"
end

execute "import ZFS public key" do
	command "rpm --import #{src_dir}/zfs_public_key"
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

# Load ZFS module at startup
file "/etc/modules-load.d/zfs.conf" do
	content "zfs"
end

# Load ZFS module immediately
execute "/sbin/modprobe zfs"

# Enable ZFS services
service "zfs-import-cache.service" do
	action :enable
end

service "zfs-import-scan.service" do
	action :enable
end

service "zfs-mount.service" do
	action :enable
end

# Disable automatic integration of ZFS dataset sharing properties
# with smb/nfs/etc
service "zfs-share.service" do
	action :disable
end

service "zfs-zed.service" do
	action :enable
end

service "zfs.target" do
	action :enable
end

# Install ZFS auto snapshot from source
zfs_snapshot_dir = "#{src_dir}/zfs-auto-snapshot"

git zfs_snapshot_dir do
	repository node["zfs-auto-snapshot"]["repository"]
	revision node["zfs-auto-snapshot"]["branch"]
	depth 1
	action :export
end

binary   = "/usr/local/sbin/zfs-auto-snapshot"
datasets = node["zfs-auto-snapshot"]["datasets"]

bash "install zfs-auto-snapshot" do
	code <<-EOH
	install -m 0644 "#{zfs_snapshot_dir}/src/zfs-auto-snapshot.8" "/usr/local/share/man/man8/zfs-auto-snapshot.8"
	install "#{zfs_snapshot_dir}/src/zfs-auto-snapshot.sh" "#{binary}"
EOH
end

# Toggle frequent snapshotting (more than once per hour)
if node["zfs-auto-snapshot"]["frequent"]["enabled"]
	cron_cmd = "*/15 * * * * root #{binary} --quiet --syslog --label=frequent --keep=#{node["zfs-auto-snapshot"]["frequent"]["keep"]} #{datasets}"
else
	cron_cmd = ""
end

file "frequent snapshot cron" do
	path "/etc/cron.d/zfs-auto-snapshot"
	mode "0644"
	content cron_cmd
end

template "hourly snapshot cron" do
	path "/etc/cron.hourly/zfs-auto-snapshot"
	source "cron.d/zfs-auto-snapshot"
	mode "0644"
	variables({
		binary:     binary,
		datasets:   datasets,
		enabled:    node["zfs-auto-snapshot"]["hourly"]["enabled"],
		keep_count: node["zfs-auto-snapshot"]["hourly"]["keep"],
		label:      "hourly"
	})
end

template "daily snapshot cron" do
	path "/etc/cron.daily/zfs-auto-snapshot"
	source "cron.d/zfs-auto-snapshot"
	mode "0644"
	variables({
		binary:     binary,
		datasets:   datasets,
		enabled:    node["zfs-auto-snapshot"]["daily"]["enabled"],
		keep_count: node["zfs-auto-snapshot"]["daily"]["keep"],
		label:      "daily"
	})
end

template "weekly snapshot cron" do
	path "/etc/cron.weekly/zfs-auto-snapshot"
	source "cron.d/zfs-auto-snapshot"
	mode "0644"
	variables({
		binary:     binary,
		datasets:   datasets,
		enabled:    node["zfs-auto-snapshot"]["weekly"]["enabled"],
		keep_count: node["zfs-auto-snapshot"]["weekly"]["keep"],
		label:      "weekly"
	})
end

template "monthly snapshot cron" do
	path "/etc/cron.monthly/zfs-auto-snapshot"
	source "cron.d/zfs-auto-snapshot"
	mode "0644"
	variables({
		binary:     binary,
		datasets:   datasets,
		enabled:    node["zfs-auto-snapshot"]["monthly"]["enabled"],
		keep_count: node["zfs-auto-snapshot"]["monthly"]["keep"],
		label:      "monthly"
	})
end
