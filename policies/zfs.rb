# zfs.rb
# Install ZFS tools alongside GeoServer installation.
# Sets up kABI installation (no DKMS required), but does not create
# any ZFS pools.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile/

# A name that describes what the system you're building with Chef does.
name 'ccadi_geoserver'

# Where to find external cookbooks:
default_source :supermarket

# run_list: chef-client will run these recipes in the order specified.
run_list 'ccadi_geoserver::zfs', 'ccadi_geoserver::default'

# Specify a custom source for a single cookbook:
cookbook 'ccadi_geoserver', path: '..'
