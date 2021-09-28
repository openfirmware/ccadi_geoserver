#
# Cookbook:: ccadi_geoserver
# Recipe:: default
#
# Copyright:: 2021, CCADI Project Contributors, All Rights Reserved.
require "uri"

def filename_from_url(url)
  uri = URI.parse(url)
  File.basename(uri.path)
end

##################
# Preconfiguration
##################

# Install fontconfig for OpenJDK to have access to system fonts
# See: https://blog.adoptopenjdk.net/2021/01/prerequisites-for-font-support-in-adoptopenjdk/
yum_package %w[freetype fontconfig dejavu-sans-fonts]

#################
# Install OpenJDK
#################
java_home = "#{node["openjdk"]["prefix"]}/jdk-#{node["openjdk"]["version"]}"

directory node["openjdk"]["prefix"] do
  recursive true
  action :create
end

jdk_filename = filename_from_url(node["openjdk"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{jdk_filename}" do
  source node["openjdk"]["download_url"]
end

bash "extract JDK" do
  cwd node["openjdk"]["prefix"]
  code <<-EOH
    tar xzf "#{Chef::Config["file_cache_path"]}/#{jdk_filename}" -C .
    EOH
  not_if { ::File.exists?(java_home) }
end

# install Apache Tomcat

# install Apache HTTP Server

# Set up HTTPS certificates and virtual hosts for HTTP Server

# Install GDAL

# Install GeoServer

# Install GeoServer Plugins

# Auto-configure GeoServer

