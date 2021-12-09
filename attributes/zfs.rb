# ZFS defaults
default["zfs-auto-snapshot"]["repository"] = "https://github.com/zfsonlinux/zfs-auto-snapshot"
default["zfs-auto-snapshot"]["branch"]     = "master"

# Specific list of ZFS dataset to backup.
# Use "//" for all.
default["zfs-auto-snapshot"]["datasets"] = "//"

default["zfs-auto-snapshot"]["frequent"]["enabled"] = true
default["zfs-auto-snapshot"]["frequent"]["keep"]    = 4

default["zfs-auto-snapshot"]["hourly"]["enabled"] = true
default["zfs-auto-snapshot"]["hourly"]["keep"]    = 12

default["zfs-auto-snapshot"]["daily"]["enabled"] = true
default["zfs-auto-snapshot"]["daily"]["keep"]    = 12

default["zfs-auto-snapshot"]["weekly"]["enabled"] = true
default["zfs-auto-snapshot"]["weekly"]["keep"]    = 12

default["zfs-auto-snapshot"]["monthly"]["enabled"] = true
default["zfs-auto-snapshot"]["monthly"]["keep"]    = 12
