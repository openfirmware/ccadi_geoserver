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
# Enable EPEL repository
yum_package 'epel-release'

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

################
# Install Tomcat
################
tomcat_home = "#{node["tomcat"]["prefix"]}/apache-tomcat-#{node["tomcat"]["version"]}"

user node["tomcat"]["user"] do
  home node["tomcat"]["prefix"]
  manage_home false
end

group node["tomcat"]["user"] do
  members node["tomcat"]["user"]
end

directory node["tomcat"]["prefix"] do
  owner node["tomcat"]["user"]
  group node["tomcat"]["user"]
  recursive true
  action :create
end

tomcat_filename = filename_from_url(node["tomcat"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{tomcat_filename}" do
  source node["tomcat"]["download_url"]
end

bash "extract Tomcat" do
  cwd node["tomcat"]["prefix"]
  user node["tomcat"]["user"]
  code <<-EOH
    tar xzf "#{Chef::Config["file_cache_path"]}/#{tomcat_filename}" -C .
    EOH
  not_if { ::File.exists?(tomcat_home) }
end

systemd_unit "tomcat.service" do
  content <<-EOU.gsub(/^\s+/, '')
  [Unit]
  Description=Apache Tomcat Web Application Container
  After=syslog.target network.target
  [Service]
  Type=forking
  User=#{node["tomcat"]["user"]}
  Group=#{node["tomcat"]["user"]}
  Environment="JAVA_HOME=#{java_home}"
  Environment="CATALINA_PID=#{tomcat_home}/temp/tomcat.pid"
  Environment="CATALINA_HOME=#{tomcat_home}"
  Environment="CATALINA_BASE=#{tomcat_home}"
  Environment="CATALINA_OPTS="
  Environment="GDAL_DATA=/usr/local/share/gdal"
  Environment="LD_LIBRARY_PATH=$LD_LIBRARY_PATH:#{tomcat_home}/lib"
  Environment="JAVA_OPTS=-Dfile.encoding=UTF-8 -Djava.library.path=/usr/local/lib:#{tomcat_home}/lib -Xms#{node["tomcat"]["Xms"]} -Xmx#{node["tomcat"]["Xmx"]}"
  ExecStart=#{tomcat_home}/bin/startup.sh
  ExecStop=/bin/kill -15 $MAINPID
  [Install]
  WantedBy=multi-user.target
  EOU

  action [:create, :enable, :start]
end

# Create resource to refer to in other resource notifications
service 'tomcat' do
  supports [:start, :stop, :restart]
  action :nothing
end

# install Apache HTTP Server

# Set up HTTPS certificates and virtual hosts for HTTP Server

# Install GDAL

# Install GeoServer

# Install GeoServer Plugins

# Auto-configure GeoServer

